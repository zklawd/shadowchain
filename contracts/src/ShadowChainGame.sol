// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IShadowVerifier} from "./interfaces/IShadowVerifier.sol";
import {MapGenerator} from "./MapGenerator.sol";
import {ArtifactRegistry} from "./ArtifactRegistry.sol";

/// @title ShadowChainGame
/// @notice Main game contract for ShadowChain — a ZK fog-of-war arena game.
///
///         Game lifecycle:
///           1. Creator calls createGame(seed, maxPlayers, entryFee)
///           2. Players call joinGame(gameId, commitment) with entry fee
///           3. Each turn: players call submitMove(gameId, newCommitment, proof)
///           4. Players can claimArtifact(gameId, proof) when on a treasure cell
///           5. Players can triggerCombat(gameId, proof) when encountering another player
///           6. Game ends via resolveGame() after max turns or when 1 player remains
///
///         All positions are hidden — verified by ZK proofs.
///         Turn timer: 60 seconds. Players who don't submit are auto-skipped.
contract ShadowChainGame is ReentrancyGuard {
    using MapGenerator for uint256;

    // =========================================================================
    //                                TYPES
    // =========================================================================

    enum GameState {
        Created,    // Waiting for players to join
        Active,     // Game in progress
        Resolved    // Game finished, winner determined
    }

    enum PlayerStatus {
        None,       // Not in game
        Alive,      // Active player
        Dead,       // Eliminated in combat
        Forfeited   // Voluntarily left
    }

    struct Game {
        uint256 id;
        uint256 seed;
        uint256 entryFee;
        uint256 prizePool;
        uint256 wallBitmap;
        uint256 treasureBitmap;
        uint32 currentTurn;
        uint32 maxTurns;
        uint8 maxPlayers;
        uint8 playerCount;
        uint8 aliveCount;
        uint64 turnDeadline;       // timestamp when current turn expires
        address creator;
        address winner;
        GameState state;
    }

    struct Player {
        address addr;
        bytes32 commitment;        // hash(x, y, salt) — current position commitment
        int16 hp;
        int8 attack;
        int8 defense;
        PlayerStatus status;
        bool hasSubmittedThisTurn;
    }

    // =========================================================================
    //                              CONSTANTS
    // =========================================================================

    uint32 public constant TURN_DURATION = 60;      // seconds per turn
    uint32 public constant DEFAULT_MAX_TURNS = 50;   // turns until timer win
    uint8 public constant MIN_PLAYERS = 2;
    uint8 public constant MAX_PLAYERS_LIMIT = 8;

    // =========================================================================
    //                               EVENTS
    // =========================================================================

    event GameCreated(
        uint256 indexed gameId,
        address indexed creator,
        uint256 seed,
        uint8 maxPlayers,
        uint256 entryFee
    );

    event PlayerJoined(
        uint256 indexed gameId,
        address indexed player,
        uint8 playerIndex
    );

    event GameStarted(
        uint256 indexed gameId,
        uint32 maxTurns,
        uint64 firstTurnDeadline
    );

    event MoveSubmitted(
        uint256 indexed gameId,
        address indexed player,
        uint32 turn,
        bytes32 newCommitment
    );

    event TurnAdvanced(
        uint256 indexed gameId,
        uint32 newTurn,
        uint64 newDeadline
    );

    event ArtifactClaimedEvent(
        uint256 indexed gameId,
        address indexed player,
        uint8 artifactId,
        uint8 cellIndex
    );

    event CombatTriggered(
        uint256 indexed gameId,
        address indexed attacker,
        address indexed defender,
        int16 damage,
        bool defenderEliminated
    );

    event PlayerEliminated(
        uint256 indexed gameId,
        address indexed player,
        uint32 turn
    );

    event PlayerForfeited(
        uint256 indexed gameId,
        address indexed player,
        uint32 turn
    );

    event GameResolved(
        uint256 indexed gameId,
        address indexed winner,
        uint256 prize
    );

    // =========================================================================
    //                               STATE
    // =========================================================================

    uint256 public nextGameId = 1;

    /// @notice Game ID → Game data
    mapping(uint256 => Game) public games;

    /// @notice Game ID → player address → Player data
    mapping(uint256 => mapping(address => Player)) public players;

    /// @notice Game ID → player index → player address
    mapping(uint256 => mapping(uint8 => address)) public playerByIndex;

    /// @notice Verifier contracts for each proof type
    IShadowVerifier public moveVerifier;
    IShadowVerifier public artifactVerifier;
    IShadowVerifier public combatVerifier;

    /// @notice Artifact registry contract
    ArtifactRegistry public artifactRegistry;

    // =========================================================================
    //                            CONSTRUCTOR
    // =========================================================================

    constructor(
        address _moveVerifier,
        address _artifactVerifier,
        address _combatVerifier,
        address _artifactRegistry
    ) {
        moveVerifier = IShadowVerifier(_moveVerifier);
        artifactVerifier = IShadowVerifier(_artifactVerifier);
        combatVerifier = IShadowVerifier(_combatVerifier);
        artifactRegistry = ArtifactRegistry(_artifactRegistry);
    }

    // =========================================================================
    //                          GAME LIFECYCLE
    // =========================================================================

    /// @notice Create a new game
    /// @param seed Seed for deterministic map generation
    /// @param maxPlayers Maximum number of players (2-8)
    /// @param entryFee Entry fee in wei (can be 0 for free games)
    /// @return gameId The ID of the created game
    function createGame(
        uint256 seed,
        uint8 maxPlayers,
        uint256 entryFee
    ) external returns (uint256 gameId) {
        require(maxPlayers >= MIN_PLAYERS && maxPlayers <= MAX_PLAYERS_LIMIT, "Invalid maxPlayers");

        gameId = nextGameId++;

        (uint256 wallBitmap, uint256 treasureBitmap) = MapGenerator.getMap(seed);

        Game storage g = games[gameId];
        g.id = gameId;
        g.seed = seed;
        g.entryFee = entryFee;
        g.maxPlayers = maxPlayers;
        g.maxTurns = DEFAULT_MAX_TURNS;
        g.creator = msg.sender;
        g.state = GameState.Created;
        g.wallBitmap = wallBitmap;
        g.treasureBitmap = treasureBitmap;

        // Assign artifacts to treasure cells
        uint8[] memory treasureCells = _getTreasureCells(treasureBitmap);
        artifactRegistry.assignArtifacts(gameId, seed, treasureCells);

        emit GameCreated(gameId, msg.sender, seed, maxPlayers, entryFee);
    }

    /// @notice Join a game by committing to a starting position
    /// @param gameId The game to join
    /// @param commitment Hash of starting position: keccak256(abi.encodePacked(x, y, salt))
    function joinGame(uint256 gameId, bytes32 commitment) external payable {
        Game storage g = games[gameId];
        require(g.state == GameState.Created, "Game not accepting players");
        require(g.playerCount < g.maxPlayers, "Game full");
        require(msg.value == g.entryFee, "Incorrect entry fee");
        require(players[gameId][msg.sender].status == PlayerStatus.None, "Already joined");
        require(commitment != bytes32(0), "Empty commitment");

        uint8 index = g.playerCount;
        g.playerCount++;
        g.aliveCount++;
        g.prizePool += msg.value;

        Player storage p = players[gameId][msg.sender];
        p.addr = msg.sender;
        p.commitment = commitment;
        p.hp = ArtifactRegistry(address(artifactRegistry)).BASE_HP();
        p.attack = ArtifactRegistry(address(artifactRegistry)).BASE_ATTACK();
        p.defense = ArtifactRegistry(address(artifactRegistry)).BASE_DEFENSE();
        p.status = PlayerStatus.Alive;

        playerByIndex[gameId][index] = msg.sender;

        emit PlayerJoined(gameId, msg.sender, index);

        // Auto-start when full
        if (g.playerCount == g.maxPlayers) {
            _startGame(gameId);
        }
    }

    /// @notice Manually start a game (creator only, requires MIN_PLAYERS)
    /// @param gameId The game to start
    function startGame(uint256 gameId) external {
        Game storage g = games[gameId];
        require(msg.sender == g.creator, "Only creator can start");
        require(g.state == GameState.Created, "Game not in created state");
        require(g.playerCount >= MIN_PLAYERS, "Not enough players");

        _startGame(gameId);
    }

    // =========================================================================
    //                          TURN ACTIONS
    // =========================================================================

    /// @notice Submit a move for the current turn
    /// @param gameId The game ID
    /// @param newCommitment New position commitment after the move
    /// @param proof ZK proof of valid move (from old commitment to new commitment)
    /// @param publicInputs Public inputs for the proof
    function submitMove(
        uint256 gameId,
        bytes32 newCommitment,
        bytes calldata proof,
        bytes32[] calldata publicInputs
    ) external {
        Game storage g = games[gameId];
        Player storage p = players[gameId][msg.sender];

        require(g.state == GameState.Active, "Game not active");
        require(p.status == PlayerStatus.Alive, "Player not alive");
        require(!p.hasSubmittedThisTurn, "Already submitted this turn");
        require(newCommitment != bytes32(0), "Empty commitment");

        // Verify ZK proof of valid move
        require(moveVerifier.verify(proof, publicInputs), "Invalid move proof");

        p.commitment = newCommitment;
        p.hasSubmittedThisTurn = true;

        emit MoveSubmitted(gameId, msg.sender, g.currentTurn, newCommitment);
    }

    /// @notice Claim an artifact at a treasure cell
    /// @param gameId The game ID
    /// @param treasureCellIndex The cell index where the treasure is
    /// @param proof ZK proof that the player is at the treasure cell
    /// @param publicInputs Public inputs for the proof
    function claimArtifact(
        uint256 gameId,
        uint8 treasureCellIndex,
        bytes calldata proof,
        bytes32[] calldata publicInputs
    ) external {
        Game storage g = games[gameId];
        Player storage p = players[gameId][msg.sender];

        require(g.state == GameState.Active, "Game not active");
        require(p.status == PlayerStatus.Alive, "Player not alive");

        // Verify the treasure cell is valid
        require((g.treasureBitmap >> treasureCellIndex) & 1 == 1, "Not a treasure cell");

        // Verify ZK proof
        require(artifactVerifier.verify(proof, publicInputs), "Invalid artifact proof");

        // Claim the artifact via registry
        uint8 artifactId = artifactRegistry.claimArtifact(gameId, msg.sender, treasureCellIndex);

        // Update player stats
        ArtifactRegistry.Artifact memory art = artifactRegistry.getArtifact(artifactId);
        p.attack += art.attackBonus;
        p.defense += art.defenseBonus;
        p.hp += art.hpBonus;

        // Floor stats
        if (p.hp < 1) p.hp = 1;
        if (p.attack < 1) p.attack = 1;
        if (p.defense < 0) p.defense = 0;

        emit ArtifactClaimedEvent(gameId, msg.sender, artifactId, treasureCellIndex);
    }

    /// @notice Trigger combat with another player
    /// @param gameId The game ID
    /// @param defender Address of the defender
    /// @param proof ZK proof of encounter (both at same cell) + attacker stats
    /// @param publicInputs Public inputs for the proof
    function triggerCombat(
        uint256 gameId,
        address defender,
        bytes calldata proof,
        bytes32[] calldata publicInputs
    ) external nonReentrant {
        Game storage g = games[gameId];
        Player storage attacker = players[gameId][msg.sender];
        Player storage def = players[gameId][defender];

        require(g.state == GameState.Active, "Game not active");
        require(attacker.status == PlayerStatus.Alive, "Attacker not alive");
        require(def.status == PlayerStatus.Alive, "Defender not alive");
        require(msg.sender != defender, "Cannot attack self");

        // Verify combat proof
        require(combatVerifier.verify(proof, publicInputs), "Invalid combat proof");

        // Calculate damage: attacker's attack - defender's defense + random modifier
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1),
            g.currentTurn,
            msg.sender,
            defender
        )));
        int16 randomMod = int16(int256(randomSeed % 7)) - 3; // -3 to +3

        int16 damage = int16(attacker.attack) - int16(def.defense) + randomMod;
        if (damage < 0) damage = 0;

        def.hp -= damage;
        bool eliminated = def.hp <= 0;

        if (eliminated) {
            def.status = PlayerStatus.Dead;
            def.hp = 0;
            g.aliveCount--;

            emit PlayerEliminated(gameId, defender, g.currentTurn);
        }

        emit CombatTriggered(gameId, msg.sender, defender, damage, eliminated);

        // Check win condition: last player standing
        if (g.aliveCount == 1) {
            _resolveByElimination(gameId);
        }
    }

    /// @notice Forfeit the game (lose stake, exit early)
    /// @param gameId The game ID
    function forfeit(uint256 gameId) external {
        Game storage g = games[gameId];
        Player storage p = players[gameId][msg.sender];

        require(g.state == GameState.Active, "Game not active");
        require(p.status == PlayerStatus.Alive, "Player not alive");

        p.status = PlayerStatus.Forfeited;
        g.aliveCount--;

        emit PlayerForfeited(gameId, msg.sender, g.currentTurn);

        // Check win condition
        if (g.aliveCount == 1) {
            _resolveByElimination(gameId);
        }
    }

    // =========================================================================
    //                        TURN MANAGEMENT
    // =========================================================================

    /// @notice Advance to the next turn. Anyone can call after turn deadline.
    /// @param gameId The game ID
    function advanceTurn(uint256 gameId) external {
        Game storage g = games[gameId];
        require(g.state == GameState.Active, "Game not active");
        require(block.timestamp >= g.turnDeadline, "Turn not expired");

        g.currentTurn++;

        // Reset per-turn state for all players
        for (uint8 i = 0; i < g.playerCount; i++) {
            address addr = playerByIndex[gameId][i];
            if (players[gameId][addr].status == PlayerStatus.Alive) {
                players[gameId][addr].hasSubmittedThisTurn = false;
            }
        }

        // Check max turns
        if (g.currentTurn > g.maxTurns) {
            _resolveByScore(gameId);
            return;
        }

        g.turnDeadline = uint64(block.timestamp + TURN_DURATION);

        emit TurnAdvanced(gameId, g.currentTurn, g.turnDeadline);
    }

    // =========================================================================
    //                       GAME RESOLUTION
    // =========================================================================

    /// @notice Force-resolve a game. Can be called if turn limit exceeded.
    /// @param gameId The game ID
    function resolveGame(uint256 gameId) external {
        Game storage g = games[gameId];
        require(g.state == GameState.Active, "Game not active");
        require(g.currentTurn > g.maxTurns || g.aliveCount <= 1, "Cannot resolve yet");

        if (g.aliveCount <= 1) {
            _resolveByElimination(gameId);
        } else {
            _resolveByScore(gameId);
        }
    }

    // =========================================================================
    //                           VIEW FUNCTIONS
    // =========================================================================

    /// @notice Get game data
    function getGame(uint256 gameId) external view returns (Game memory) {
        return games[gameId];
    }

    /// @notice Get player data
    function getPlayer(uint256 gameId, address addr) external view returns (Player memory) {
        return players[gameId][addr];
    }

    /// @notice Get the map bitmaps for a game
    function getGameMap(uint256 gameId) external view returns (uint256 wallBitmap, uint256 treasureBitmap) {
        Game storage g = games[gameId];
        return (g.wallBitmap, g.treasureBitmap);
    }

    /// @notice Check if a cell is a wall
    function isWall(uint256 gameId, uint8 x, uint8 y) external view returns (bool) {
        uint8 idx = MapGenerator.cellIndex(x, y);
        return (games[gameId].wallBitmap >> idx) & 1 == 1;
    }

    /// @notice Check if a cell is a treasure cell
    function isTreasure(uint256 gameId, uint8 x, uint8 y) external view returns (bool) {
        uint8 idx = MapGenerator.cellIndex(x, y);
        return (games[gameId].treasureBitmap >> idx) & 1 == 1;
    }

    // =========================================================================
    //                        INTERNAL FUNCTIONS
    // =========================================================================

    function _startGame(uint256 gameId) internal {
        Game storage g = games[gameId];
        g.state = GameState.Active;
        g.currentTurn = 1;
        g.turnDeadline = uint64(block.timestamp + TURN_DURATION);

        emit GameStarted(gameId, g.maxTurns, g.turnDeadline);
    }

    function _resolveByElimination(uint256 gameId) internal {
        Game storage g = games[gameId];

        // Find the last standing player
        address winner;
        for (uint8 i = 0; i < g.playerCount; i++) {
            address addr = playerByIndex[gameId][i];
            if (players[gameId][addr].status == PlayerStatus.Alive) {
                winner = addr;
                break;
            }
        }

        _finalize(gameId, winner);
    }

    function _resolveByScore(uint256 gameId) internal {
        Game storage g = games[gameId];

        // Score = HP + (artifacts * 10). Highest wins.
        address bestPlayer;
        int256 bestScore = type(int256).min;

        for (uint8 i = 0; i < g.playerCount; i++) {
            address addr = playerByIndex[gameId][i];
            Player storage p = players[gameId][addr];

            if (p.status != PlayerStatus.Alive) continue;

            uint8[] memory arts = artifactRegistry.getPlayerArtifactIds(gameId, addr);
            int256 score = int256(p.hp) + int256(uint256(arts.length)) * 10;

            if (score > bestScore) {
                bestScore = score;
                bestPlayer = addr;
            }
        }

        _finalize(gameId, bestPlayer);
    }

    function _finalize(uint256 gameId, address winner) internal {
        Game storage g = games[gameId];
        g.state = GameState.Resolved;
        g.winner = winner;

        uint256 prize = g.prizePool;
        g.prizePool = 0;

        if (winner != address(0) && prize > 0) {
            (bool success,) = winner.call{value: prize}("");
            require(success, "Prize transfer failed");
        }

        emit GameResolved(gameId, winner, prize);
    }

    /// @dev Extract treasure cell indices from a bitmap
    function _getTreasureCells(uint256 bitmap) internal pure returns (uint8[] memory) {
        // Count set bits first
        uint8 count = 0;
        for (uint16 i = 0; i < 256; i++) {
            if ((bitmap >> i) & 1 == 1) count++;
        }

        uint8[] memory cells = new uint8[](count);
        uint8 idx = 0;
        for (uint16 i = 0; i < 256; i++) {
            if ((bitmap >> i) & 1 == 1) {
                cells[idx++] = uint8(i);
            }
        }

        return cells;
    }

    /// @notice Receive ETH (for prize payouts returning)
    receive() external payable {}
}
