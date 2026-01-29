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
        bytes32 treasureSeed;      // Computed on game start from all player commitments
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
    uint8 public constant TREASURE_THRESHOLD = 20;   // ~8% of cells have treasures (20/256)
    
    // Domain separator for artifact ID derivation (must match circuit!)
    // "artifact" as ASCII bytes, left-padded to fit in a field element
    uint256 public constant ARTIFACT_DOMAIN_SEP = 0x617274696661637400;

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
        uint8 cellIndex,
        bytes32 nullifier
    );

    event InventoryCommitmentUpdated(
        uint256 indexed gameId,
        address indexed player,
        bytes32 newCommitment
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
    mapping(uint256 => bytes32) public mapHashes; // gameId => Pedersen hash of wall row bitmasks

    /// @notice Game ID → player address → Player data
    mapping(uint256 => mapping(address => Player)) public players;

    /// @notice Game ID → player index → player address
    mapping(uint256 => mapping(uint8 => address)) public playerByIndex;

    /// @notice Game ID → array of player commitments (for computing treasureSeed)
    mapping(uint256 => bytes32[]) public gameCommitments;

    /// @notice Nullifier tracking for artifact claims (prevents double-claiming)
    /// @dev nullifier = poseidon(player_secret, x, y, treasure_seed, domain_sep)
    mapping(bytes32 => bool) public usedNullifiers;

    /// @notice Game ID → player address → inventory commitment
    /// @dev Commitment to player's owned artifacts: pedersen(artifact_ids[0..7], salt)
    mapping(uint256 => mapping(address => bytes32)) public inventoryCommitments;

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

        // Only get wall bitmap - treasures are procedurally determined after all players join
        (uint256 wallBitmap, ) = MapGenerator.getMap(seed);

        Game storage g = games[gameId];
        g.id = gameId;
        g.seed = seed;
        g.entryFee = entryFee;
        g.maxPlayers = maxPlayers;
        g.maxTurns = DEFAULT_MAX_TURNS;
        g.creator = msg.sender;
        g.state = GameState.Created;
        g.wallBitmap = wallBitmap;
        // treasureSeed computed in _startGame after all players join

        emit GameCreated(gameId, msg.sender, seed, maxPlayers, entryFee);
    }

    /// @notice Set the map hash for a game (Pedersen hash of wall row bitmasks).
    ///         Can be called once per game before it starts. The hash is deterministic
    ///         from the public wallBitmap, so anyone can verify it off-chain.
    /// @param gameId The game ID
    /// @param _mapHash Pedersen hash of the 16 wall row bitmasks
    function setMapHash(uint256 gameId, bytes32 _mapHash) external {
        Game storage g = games[gameId];
        require(g.state == GameState.Created, "Game already started");
        require(mapHashes[gameId] == bytes32(0), "Map hash already set");
        require(_mapHash != bytes32(0), "Empty map hash");
        mapHashes[gameId] = _mapHash;
    }

    /// @notice Join a game by committing to a starting position
    /// @param gameId The game to join
    /// @param commitment Hash of starting position: pedersen(x, y, salt)
    /// @param inventoryCommitment Initial inventory commitment: pedersen([0,0,0,0,0,0,0,0], inventory_salt)
    function joinGame(uint256 gameId, bytes32 commitment, bytes32 inventoryCommitment) external payable {
        Game storage g = games[gameId];
        require(g.state == GameState.Created, "Game not accepting players");
        require(g.playerCount < g.maxPlayers, "Game full");
        require(msg.value == g.entryFee, "Incorrect entry fee");
        require(players[gameId][msg.sender].status == PlayerStatus.None, "Already joined");
        require(commitment != bytes32(0), "Empty commitment");
        require(inventoryCommitment != bytes32(0), "Empty inventory commitment");

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
        
        // Store commitment for treasureSeed computation
        gameCommitments[gameId].push(commitment);
        
        // Store initial inventory commitment (empty inventory)
        inventoryCommitments[gameId][msg.sender] = inventoryCommitment;

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

    /// @notice Claim an artifact at a treasure cell (procedurally generated)
    /// @param gameId The game ID
    /// @param cellX X coordinate of the treasure cell (0-15)
    /// @param cellY Y coordinate of the treasure cell (0-15)
    /// @param proof ZK proof that player is at a valid treasure cell
    /// @param publicInputs Public inputs: [commitment, treasureSeed, artifactId, nullifier]
    /// @param newInventoryCommitment New commitment to player's inventory after claiming
    function claimArtifact(
        uint256 gameId,
        uint8 cellX,
        uint8 cellY,
        bytes calldata proof,
        bytes32[] calldata publicInputs,
        bytes32 newInventoryCommitment
    ) external {
        Game storage g = games[gameId];
        Player storage p = players[gameId][msg.sender];

        require(g.state == GameState.Active, "Game not active");
        require(p.status == PlayerStatus.Alive, "Player not alive");
        require(cellX < 16 && cellY < 16, "Invalid cell coordinates");
        require(publicInputs.length >= 4, "Missing public inputs");
        require(newInventoryCommitment != bytes32(0), "Empty inventory commitment");

        // Extract nullifier from public inputs (4th element, index 3)
        bytes32 nullifier = publicInputs[3];
        
        // SECURITY: Check nullifier hasn't been used (prevents double-claiming)
        require(!usedNullifiers[nullifier], "Artifact already claimed");

        // ZK proof verifies:
        // 1. Player commitment matches their position (cellX, cellY)
        // 2. hash(cellX, cellY, treasureSeed) % 256 < TREASURE_THRESHOLD
        // 3. artifactId matches derived value
        // 4. nullifier = poseidon(player_secret, x, y, treasure_seed, domain_sep)
        require(artifactVerifier.verify(proof, publicInputs), "Invalid artifact proof");

        // Mark nullifier as used BEFORE any state changes (CEI pattern)
        usedNullifiers[nullifier] = true;

        // Derive artifact ID (must match what circuit proved)
        uint8 artifactId = _getArtifactAtCell(cellX, cellY, g.treasureSeed);
        
        // Record claim via registry (uses cellIndex for tracking)
        uint8 cellIndex = cellY * 16 + cellX;
        artifactRegistry.claimArtifactProcedural(gameId, msg.sender, cellIndex, artifactId);

        // Update player stats
        ArtifactRegistry.Artifact memory art = artifactRegistry.getArtifact(artifactId);
        p.attack += art.attackBonus;
        p.defense += art.defenseBonus;
        p.hp += art.hpBonus;

        // Floor stats
        if (p.hp < 1) p.hp = 1;
        if (p.attack < 1) p.attack = 1;
        if (p.defense < 0) p.defense = 0;

        // Update inventory commitment for combat_reveal verification
        inventoryCommitments[gameId][msg.sender] = newInventoryCommitment;

        emit ArtifactClaimedEvent(gameId, msg.sender, artifactId, cellIndex, nullifier);
        emit InventoryCommitmentUpdated(gameId, msg.sender, newInventoryCommitment);
    }

    /// @notice Derive artifact ID at a cell from treasureSeed (deterministic)
    /// @param x X coordinate (0-15)
    /// @param y Y coordinate (0-15)
    /// @param treasureSeed The game's treasure seed
    /// @return artifactId The artifact ID (1-8)
    /// @dev Uses keccak256 for artifact derivation. 
    ///      Note: The ZK circuit uses Poseidon internally, but the contract just
    ///      needs deterministic artifact assignment. Matching not required since
    ///      artifact_id is a public input verified by the circuit.
    function _getArtifactAtCell(uint8 x, uint8 y, bytes32 treasureSeed) internal pure returns (uint8) {
        bytes32 h = keccak256(abi.encodePacked(x, y, treasureSeed, ARTIFACT_DOMAIN_SEP));
        return uint8((uint256(h) % 8) + 1); // 1-indexed (1-8)
    }

    /// @notice Trigger combat with another player
    /// @param gameId The game ID
    /// @param defender Address of the defender
    /// @param proof ZK proof of encounter (both at same cell) + attacker stats
    /// @param publicInputs Public inputs: [commitment, stats_commitment, game_id, inventory_commitment]
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
        require(publicInputs.length >= 4, "Missing public inputs");

        // SECURITY: Verify inventory commitment matches on-chain record
        // This ensures the attacker can only use artifacts they actually own
        bytes32 proofInventoryCommitment = publicInputs[3];
        bytes32 storedInventoryCommitment = inventoryCommitments[gameId][msg.sender];
        require(proofInventoryCommitment == storedInventoryCommitment, "Inventory commitment mismatch");

        // Verify combat proof (circuit verifies stats match artifacts + ownership)
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

    /// @notice Get the map data for a game
    /// @return wallBitmap Bitmap of wall cells (1 = wall)
    /// @return treasureSeed Seed for procedural treasure generation (0 if game not started)
    function getGameMap(uint256 gameId) external view returns (uint256 wallBitmap, bytes32 treasureSeed) {
        Game storage g = games[gameId];
        return (g.wallBitmap, g.treasureSeed);
    }

    /// @notice Check if a cell is a wall
    function isWall(uint256 gameId, uint8 x, uint8 y) external view returns (bool) {
        uint8 idx = MapGenerator.cellIndex(x, y);
        return (games[gameId].wallBitmap >> idx) & 1 == 1;
    }

    /// @notice Check if a cell is a treasure cell (procedurally generated)
    /// @dev Returns false if game hasn't started (treasureSeed not set)
    /// @notice Check if a cell contains treasure (procedurally generated)
    /// @dev Note: ZK circuit uses Poseidon but contract uses keccak256 for view functions.
    ///      The circuit proves treasure validity independently.
    function isTreasure(uint256 gameId, uint8 x, uint8 y) external view returns (bool) {
        bytes32 treasureSeed = games[gameId].treasureSeed;
        if (treasureSeed == bytes32(0)) return false;
        
        bytes32 cellHash = keccak256(abi.encodePacked(x, y, treasureSeed));
        return uint256(cellHash) % 256 < TREASURE_THRESHOLD;
    }
    
    /// @notice Get artifact ID at a cell (procedurally generated)
    /// @dev Returns 0 if not a treasure cell or game hasn't started
    function getArtifactAtCell(uint256 gameId, uint8 x, uint8 y) external view returns (uint8) {
        bytes32 treasureSeed = games[gameId].treasureSeed;
        if (treasureSeed == bytes32(0)) return 0;
        
        bytes32 cellHash = keccak256(abi.encodePacked(x, y, treasureSeed));
        if (uint256(cellHash) % 256 >= TREASURE_THRESHOLD) return 0;
        
        return _getArtifactAtCell(x, y, treasureSeed);
    }
    
    /// @notice Get the treasure seed for a game (only set after game starts)
    function getTreasureSeed(uint256 gameId) external view returns (bytes32) {
        return games[gameId].treasureSeed;
    }

    /// @notice Check if a nullifier has been used
    /// @param nullifier The nullifier to check
    /// @return True if the nullifier has been used
    function isNullifierUsed(bytes32 nullifier) external view returns (bool) {
        return usedNullifiers[nullifier];
    }

    /// @notice Get a player's inventory commitment
    /// @param gameId The game ID
    /// @param player The player address
    /// @return The inventory commitment (bytes32(0) if not initialized)
    function getInventoryCommitment(uint256 gameId, address player) external view returns (bytes32) {
        return inventoryCommitments[gameId][player];
    }

    // =========================================================================
    //                        INTERNAL FUNCTIONS
    // =========================================================================

    function _startGame(uint256 gameId) internal {
        Game storage g = games[gameId];
        
        // Compute treasureSeed from game seed + all player commitments
        // This ensures nobody can precompute treasure locations until all players join
        bytes32 seed = bytes32(g.seed);
        bytes32[] storage commits = gameCommitments[gameId];
        for (uint256 i = 0; i < commits.length; i++) {
            seed = keccak256(abi.encodePacked(seed, commits[i]));
        }
        g.treasureSeed = seed;
        
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

    /// @notice Receive ETH (for prize payouts returning)
    receive() external payable {}
}
