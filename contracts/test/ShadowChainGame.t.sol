// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {ShadowChainGame} from "../src/ShadowChainGame.sol";
import {ArtifactRegistry} from "../src/ArtifactRegistry.sol";
import {MockVerifier, RejectVerifier} from "../src/MockVerifier.sol";
import {MapGenerator} from "../src/MapGenerator.sol";

contract ShadowChainGameTest is Test {
    ShadowChainGame public game;
    ArtifactRegistry public registry;
    MockVerifier public mockVerifier;
    RejectVerifier public rejectVerifier;

    address creator = makeAddr("creator");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");
    address dave = makeAddr("dave");

    uint256 constant SEED = 42;
    uint256 constant ENTRY_FEE = 0.1 ether;
    uint8 constant MAX_PLAYERS = 4;

    // Dummy proof data (MockVerifier always returns true)
    bytes constant DUMMY_PROOF = hex"deadbeef";
    bytes32[] DUMMY_INPUTS;
    
    // Dummy nullifier and inventory commitment for tests
    bytes32 constant DUMMY_NULLIFIER = keccak256("nullifier");
    bytes32 constant DUMMY_INVENTORY_COMMITMENT = keccak256("inventory");

    function setUp() public {
        mockVerifier = new MockVerifier();
        rejectVerifier = new RejectVerifier();
        registry = new ArtifactRegistry();

        game = new ShadowChainGame(
            address(mockVerifier),   // moveVerifier
            address(mockVerifier),   // artifactVerifier
            address(mockVerifier),   // combatVerifier
            address(registry)
        );

        // Link registry to game (H-02 security fix)
        registry.setGameContract(address(game));

        // Fund test accounts
        vm.deal(creator, 10 ether);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);
        vm.deal(dave, 10 ether);

        // Set up dummy inputs (4 elements for claim_artifact and combat_reveal)
        // For claim_artifact: [commitment, treasureSeed, artifactId, nullifier]
        // For combat_reveal: [commitment, statsCommitment, gameId, inventoryCommitment]
        DUMMY_INPUTS = new bytes32[](4);
        DUMMY_INPUTS[0] = bytes32(uint256(1));
        DUMMY_INPUTS[1] = bytes32(uint256(2));
        DUMMY_INPUTS[2] = bytes32(uint256(3));
        DUMMY_INPUTS[3] = DUMMY_INVENTORY_COMMITMENT; // Used for combat (inventory commitment)
    }

    // =========================================================================
    //                        HELPER FUNCTIONS
    // =========================================================================

    /// @dev Create a game and return its ID
    function _createGame() internal returns (uint256 gameId) {
        vm.prank(creator);
        gameId = game.createGame(SEED, MAX_PLAYERS, ENTRY_FEE);
    }

    /// @dev Create a game with zero entry fee
    function _createFreeGame() internal returns (uint256 gameId) {
        vm.prank(creator);
        gameId = game.createGame(SEED, MAX_PLAYERS, 0);
    }

    /// @dev Join a game as a player (includes inventory commitment)
    function _joinGame(uint256 gameId, address player, bytes32 commitment) internal {
        vm.prank(player);
        game.joinGame{value: ENTRY_FEE}(gameId, commitment, DUMMY_INVENTORY_COMMITMENT);
    }

    /// @dev Join a free game (includes inventory commitment)
    function _joinFreeGame(uint256 gameId, address player, bytes32 commitment) internal {
        vm.prank(player);
        game.joinGame{value: 0}(gameId, commitment, DUMMY_INVENTORY_COMMITMENT);
    }

    /// @dev Create and fill a 2-player game, auto-starting it
    function _createAndStartGame() internal returns (uint256 gameId) {
        vm.prank(creator);
        gameId = game.createGame(SEED, 2, ENTRY_FEE);

        // Set map hash before players join (so submitMove can verify it)
        vm.prank(creator);
        game.setMapHash(gameId, keccak256("map_hash"));

        vm.prank(alice);
        game.joinGame{value: ENTRY_FEE}(gameId, keccak256("alice_pos"), DUMMY_INVENTORY_COMMITMENT);

        vm.prank(bob);
        game.joinGame{value: ENTRY_FEE}(gameId, keccak256("bob_pos"), DUMMY_INVENTORY_COMMITMENT);
    }

    /// @dev Build public inputs for submitMove
    /// @param oldCommitment The player's current commitment
    /// @param newCommitment The new commitment after the move
    /// @param gameId The game ID
    /// @return inputs The public inputs array [old, new, mapHash, gameId]
    function _buildMoveInputs(
        bytes32 oldCommitment,
        bytes32 newCommitment,
        uint256 gameId
    ) internal view returns (bytes32[] memory inputs) {
        inputs = new bytes32[](4);
        inputs[0] = oldCommitment;
        inputs[1] = newCommitment;
        inputs[2] = game.mapHashes(gameId);
        inputs[3] = bytes32(gameId);
    }

    /// @dev Create, fill, and start a 4-player game
    function _createAndStartFullGame() internal returns (uint256 gameId) {
        gameId = _createGame();
        // Set map hash before players join
        vm.prank(creator);
        game.setMapHash(gameId, keccak256("map_hash"));
        _joinGame(gameId, alice, keccak256("alice_pos"));
        _joinGame(gameId, bob, keccak256("bob_pos"));
        _joinGame(gameId, charlie, keccak256("charlie_pos"));
        _joinGame(gameId, dave, keccak256("dave_pos"));
        // Game auto-starts when full
    }

    // =========================================================================
    //                      GAME CREATION TESTS
    // =========================================================================

    function test_createGame() public {
        vm.prank(creator);
        uint256 gameId = game.createGame(SEED, MAX_PLAYERS, ENTRY_FEE);

        assertEq(gameId, 1, "First game should have ID 1");

        ShadowChainGame.Game memory g = game.getGame(gameId);
        assertEq(g.seed, SEED);
        assertEq(g.entryFee, ENTRY_FEE);
        assertEq(g.maxPlayers, MAX_PLAYERS);
        assertEq(g.prizePool, 0);
        assertEq(g.currentTurn, 0);
        assertEq(g.playerCount, 0);
        assertEq(g.aliveCount, 0);
        assertEq(g.creator, creator);
        assertEq(uint8(g.state), uint8(ShadowChainGame.GameState.Created));
    }

    function test_createGame_emitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit ShadowChainGame.GameCreated(1, creator, SEED, MAX_PLAYERS, ENTRY_FEE);

        vm.prank(creator);
        game.createGame(SEED, MAX_PLAYERS, ENTRY_FEE);
    }

    function test_createGame_incrementsId() public {
        vm.startPrank(creator);
        uint256 id1 = game.createGame(1, 2, 0);
        uint256 id2 = game.createGame(2, 2, 0);
        uint256 id3 = game.createGame(3, 2, 0);
        vm.stopPrank();

        assertEq(id1, 1);
        assertEq(id2, 2);
        assertEq(id3, 3);
    }

    function test_createGame_freeEntry() public {
        vm.prank(creator);
        uint256 gameId = game.createGame(SEED, 2, 0);
        ShadowChainGame.Game memory g = game.getGame(gameId);
        assertEq(g.entryFee, 0);
    }

    function test_createGame_invalidMaxPlayers_reverts() public {
        vm.startPrank(creator);

        vm.expectRevert("Invalid maxPlayers");
        game.createGame(SEED, 1, ENTRY_FEE); // too few

        vm.expectRevert("Invalid maxPlayers");
        game.createGame(SEED, 9, ENTRY_FEE); // too many

        vm.stopPrank();
    }

    function test_createGame_mapsGenerated() public {
        vm.prank(creator);
        uint256 gameId = game.createGame(SEED, 2, 0);

        (uint256 wallBitmap, bytes32 treasureSeed) = game.getGameMap(gameId);
        (uint256 expectedWalls, ) = MapGenerator.getMap(SEED);

        assertEq(wallBitmap, expectedWalls, "Walls should match MapGenerator");
        assertEq(treasureSeed, bytes32(0), "TreasureSeed should be 0 before game starts");
    }
    
    function test_treasureSeed_computedOnStart() public {
        // Create a 2-player game (so auto-start triggers after both join)
        vm.prank(creator);
        uint256 gameId = game.createGame(SEED, 2, ENTRY_FEE);
        
        // Before start, treasureSeed is 0
        (, bytes32 seedBefore) = game.getGameMap(gameId);
        assertEq(seedBefore, bytes32(0), "TreasureSeed should be 0 before start");
        
        // Join both players to trigger auto-start
        bytes32 commit1 = keccak256("alice_pos");
        bytes32 commit2 = keccak256("bob_pos");
        
        vm.prank(alice);
        game.joinGame{value: ENTRY_FEE}(gameId, commit1, DUMMY_INVENTORY_COMMITMENT);
        vm.prank(bob);
        game.joinGame{value: ENTRY_FEE}(gameId, commit2, DUMMY_INVENTORY_COMMITMENT);
        
        // After start, treasureSeed should be computed from seed + commitments
        (, bytes32 seedAfter) = game.getGameMap(gameId);
        assertTrue(seedAfter != bytes32(0), "TreasureSeed should be set after start");
        
        // Verify it's deterministic: hash(seed, commit1, commit2)
        bytes32 expected = keccak256(abi.encodePacked(bytes32(SEED), commit1));
        expected = keccak256(abi.encodePacked(expected, commit2));
        assertEq(seedAfter, expected, "TreasureSeed should match expected computation");
    }

    // =========================================================================
    //                       JOIN GAME TESTS
    // =========================================================================

    function test_joinGame() public {
        uint256 gameId = _createGame();
        bytes32 commitment = keccak256("alice_pos");

        vm.prank(alice);
        game.joinGame{value: ENTRY_FEE}(gameId, commitment, DUMMY_INVENTORY_COMMITMENT);

        ShadowChainGame.Player memory p = game.getPlayer(gameId, alice);
        assertEq(p.addr, alice);
        assertEq(p.commitment, commitment);
        assertEq(p.hp, int16(100));
        assertEq(p.attack, int8(10));
        assertEq(p.defense, int8(5));
        assertEq(uint8(p.status), uint8(ShadowChainGame.PlayerStatus.Alive));

        ShadowChainGame.Game memory g = game.getGame(gameId);
        assertEq(g.playerCount, 1);
        assertEq(g.aliveCount, 1);
        assertEq(g.prizePool, ENTRY_FEE);
    }

    function test_joinGame_emitsEvent() public {
        uint256 gameId = _createGame();

        vm.expectEmit(true, true, false, true);
        emit ShadowChainGame.PlayerJoined(gameId, alice, 0);

        vm.prank(alice);
        game.joinGame{value: ENTRY_FEE}(gameId, keccak256("pos"), DUMMY_INVENTORY_COMMITMENT);
    }

    function test_joinGame_wrongFee_reverts() public {
        uint256 gameId = _createGame();

        vm.prank(alice);
        vm.expectRevert("Incorrect entry fee");
        game.joinGame{value: 0.05 ether}(gameId, keccak256("pos"), DUMMY_INVENTORY_COMMITMENT);
    }

    function test_joinGame_alreadyJoined_reverts() public {
        uint256 gameId = _createGame();

        vm.startPrank(alice);
        game.joinGame{value: ENTRY_FEE}(gameId, keccak256("pos"), DUMMY_INVENTORY_COMMITMENT);

        vm.expectRevert("Already joined");
        game.joinGame{value: ENTRY_FEE}(gameId, keccak256("pos2"), DUMMY_INVENTORY_COMMITMENT);
        vm.stopPrank();
    }

    function test_joinGame_emptyCommitment_reverts() public {
        uint256 gameId = _createGame();

        vm.prank(alice);
        vm.expectRevert("Empty commitment");
        game.joinGame{value: ENTRY_FEE}(gameId, bytes32(0), DUMMY_INVENTORY_COMMITMENT);
    }

    function test_joinGame_emptyInventoryCommitment_reverts() public {
        uint256 gameId = _createGame();

        vm.prank(alice);
        vm.expectRevert("Empty inventory commitment");
        game.joinGame{value: ENTRY_FEE}(gameId, keccak256("pos"), bytes32(0));
    }

    function test_joinGame_gameFull_reverts() public {
        uint256 gameId = _createAndStartFullGame();

        address extra = makeAddr("extra");
        vm.deal(extra, 1 ether);
        vm.prank(extra);
        vm.expectRevert("Game not accepting players");
        game.joinGame{value: ENTRY_FEE}(gameId, keccak256("extra_pos"), DUMMY_INVENTORY_COMMITMENT);
    }

    function test_joinGame_autoStartsWhenFull() public {
        vm.prank(creator);
        uint256 gameId = game.createGame(SEED, 2, ENTRY_FEE);

        vm.prank(alice);
        game.joinGame{value: ENTRY_FEE}(gameId, keccak256("alice"), DUMMY_INVENTORY_COMMITMENT);

        // Not started yet
        ShadowChainGame.Game memory g1 = game.getGame(gameId);
        assertEq(uint8(g1.state), uint8(ShadowChainGame.GameState.Created));

        // Second player triggers auto-start
        vm.prank(bob);
        game.joinGame{value: ENTRY_FEE}(gameId, keccak256("bob"), DUMMY_INVENTORY_COMMITMENT);

        ShadowChainGame.Game memory g2 = game.getGame(gameId);
        assertEq(uint8(g2.state), uint8(ShadowChainGame.GameState.Active));
        assertEq(g2.currentTurn, 1);
        assertTrue(g2.turnDeadline > 0);
    }

    function test_joinGame_prizePoolAccumulates() public {
        uint256 gameId = _createAndStartFullGame();
        ShadowChainGame.Game memory g = game.getGame(gameId);
        assertEq(g.prizePool, ENTRY_FEE * 4);
    }

    // =========================================================================
    //                     MANUAL START TESTS
    // =========================================================================

    function test_startGame_manual() public {
        uint256 gameId = _createGame();
        _joinGame(gameId, alice, keccak256("alice"));
        _joinGame(gameId, bob, keccak256("bob"));

        // Not full yet (4 max), manually start
        vm.prank(creator);
        game.startGame(gameId);

        ShadowChainGame.Game memory g = game.getGame(gameId);
        assertEq(uint8(g.state), uint8(ShadowChainGame.GameState.Active));
        assertEq(g.currentTurn, 1);
    }

    function test_startGame_emitsEvent() public {
        uint256 gameId = _createGame();
        _joinGame(gameId, alice, keccak256("alice"));
        _joinGame(gameId, bob, keccak256("bob"));

        vm.expectEmit(true, false, false, true);
        emit ShadowChainGame.GameStarted(gameId, 50, uint64(block.timestamp + 60));

        vm.prank(creator);
        game.startGame(gameId);
    }

    function test_startGame_notCreator_reverts() public {
        uint256 gameId = _createGame();
        _joinGame(gameId, alice, keccak256("alice"));
        _joinGame(gameId, bob, keccak256("bob"));

        vm.prank(alice);
        vm.expectRevert("Only creator can start");
        game.startGame(gameId);
    }

    function test_startGame_notEnoughPlayers_reverts() public {
        uint256 gameId = _createGame();
        _joinGame(gameId, alice, keccak256("alice"));

        vm.prank(creator);
        vm.expectRevert("Not enough players");
        game.startGame(gameId);
    }

    function test_startGame_alreadyActive_reverts() public {
        uint256 gameId = _createAndStartGame();

        vm.prank(creator);
        vm.expectRevert("Game not in created state");
        game.startGame(gameId);
    }

    // =========================================================================
    //                      SUBMIT MOVE TESTS
    // =========================================================================

    function test_submitMove() public {
        uint256 gameId = _createAndStartGame();
        bytes32 oldCommitment = keccak256("alice_pos");
        bytes32 newCommitment = keccak256("alice_new_pos");
        
        // Build inputs before prank (vm.prank only affects next external call)
        bytes32[] memory moveInputs = _buildMoveInputs(oldCommitment, newCommitment, gameId);

        vm.prank(alice);
        game.submitMove(gameId, newCommitment, DUMMY_PROOF, moveInputs);

        ShadowChainGame.Player memory p = game.getPlayer(gameId, alice);
        assertEq(p.commitment, newCommitment);
        assertTrue(p.hasSubmittedThisTurn);
    }

    function test_submitMove_emitsEvent() public {
        uint256 gameId = _createAndStartGame();
        bytes32 oldCommitment = keccak256("alice_pos");
        bytes32 newCommitment = keccak256("alice_new_pos");
        
        // Build inputs before prank
        bytes32[] memory moveInputs = _buildMoveInputs(oldCommitment, newCommitment, gameId);

        vm.expectEmit(true, true, false, true);
        emit ShadowChainGame.MoveSubmitted(gameId, alice, 1, newCommitment);

        vm.prank(alice);
        game.submitMove(gameId, newCommitment, DUMMY_PROOF, moveInputs);
    }

    function test_submitMove_gameNotActive_reverts() public {
        uint256 gameId = _createGame();
        _joinGame(gameId, alice, keccak256("alice"));

        vm.prank(alice);
        vm.expectRevert("Game not active");
        game.submitMove(gameId, keccak256("new"), DUMMY_PROOF, DUMMY_INPUTS);
    }

    function test_submitMove_notAlive_reverts() public {
        // Use 4-player game so forfeiting doesn't end the game
        uint256 gameId = _createAndStartFullGame();

        // Alice forfeits
        vm.prank(alice);
        game.forfeit(gameId);

        vm.prank(alice);
        vm.expectRevert("Player not alive");
        game.submitMove(gameId, keccak256("new"), DUMMY_PROOF, DUMMY_INPUTS);
    }

    function test_submitMove_alreadySubmitted_reverts() public {
        uint256 gameId = _createAndStartGame();
        bytes32 oldCommitment = keccak256("alice_pos");
        bytes32 move1 = keccak256("move1");
        bytes32 move2 = keccak256("move2");

        // Build inputs before prank
        bytes32[] memory moveInputs1 = _buildMoveInputs(oldCommitment, move1, gameId);
        bytes32[] memory moveInputs2 = _buildMoveInputs(move1, move2, gameId);

        vm.startPrank(alice);
        game.submitMove(gameId, move1, DUMMY_PROOF, moveInputs1);

        vm.expectRevert("Already submitted this turn");
        game.submitMove(gameId, move2, DUMMY_PROOF, moveInputs2);
        vm.stopPrank();
    }

    function test_submitMove_emptyCommitment_reverts() public {
        uint256 gameId = _createAndStartGame();

        vm.prank(alice);
        vm.expectRevert("Empty commitment");
        game.submitMove(gameId, bytes32(0), DUMMY_PROOF, DUMMY_INPUTS);
    }

    function test_submitMove_invalidProof_reverts() public {
        // Deploy game with reject verifier and its own registry
        ArtifactRegistry strictRegistry = new ArtifactRegistry();
        ShadowChainGame strictGame = new ShadowChainGame(
            address(rejectVerifier),
            address(mockVerifier),
            address(mockVerifier),
            address(strictRegistry)
        );
        strictRegistry.setGameContract(address(strictGame));

        vm.prank(creator);
        uint256 gameId = strictGame.createGame(SEED, 2, 0);

        // Set map hash before players join
        vm.prank(creator);
        strictGame.setMapHash(gameId, keccak256("map_hash"));

        bytes32 aliceCommit = keccak256("alice");
        vm.prank(alice);
        strictGame.joinGame(gameId, aliceCommit, DUMMY_INVENTORY_COMMITMENT);
        vm.prank(bob);
        strictGame.joinGame(gameId, keccak256("bob"), DUMMY_INVENTORY_COMMITMENT);

        // Build proper public inputs
        bytes32 newCommitment = keccak256("new");
        bytes32[] memory moveInputs = new bytes32[](4);
        moveInputs[0] = aliceCommit;
        moveInputs[1] = newCommitment;
        moveInputs[2] = strictGame.mapHashes(gameId);
        moveInputs[3] = bytes32(gameId);

        vm.prank(alice);
        vm.expectRevert("Invalid move proof");
        strictGame.submitMove(gameId, newCommitment, DUMMY_PROOF, moveInputs);
    }

    // =========================================================================
    //                     CLAIM ARTIFACT TESTS
    // =========================================================================

    function test_claimArtifact() public {
        uint256 gameId = _createAndStartGame();

        // Find a treasure cell using procedural generation
        (, bytes32 treasureSeed) = game.getGameMap(gameId);
        (uint8 x, uint8 y) = _findFirstProceduralTreasure(treasureSeed);
        require(x != 255, "No treasure cells found");
        
        uint8 cellIndex = y * 16 + x;

        vm.prank(alice);
        game.claimArtifact(gameId, x, y, DUMMY_PROOF, DUMMY_INPUTS, DUMMY_INVENTORY_COMMITMENT);

        // Check artifact was claimed
        address claimer = registry.claimedBy(gameId, cellIndex);
        assertEq(claimer, alice);
    }

    function test_claimArtifact_emitsEvent() public {
        uint256 gameId = _createAndStartGame();
        (, bytes32 treasureSeed) = game.getGameMap(gameId);
        (uint8 x, uint8 y) = _findFirstProceduralTreasure(treasureSeed);
        uint8 cellIndex = y * 16 + x;

        // Get expected artifact ID from contract helper
        uint8 expectedArtifactId = game.getArtifactAtCell(gameId, x, y);

        // Create inputs with nullifier (claim_artifact uses nullifier in publicInputs[3])
        bytes32[] memory claimInputs = new bytes32[](4);
        claimInputs[0] = DUMMY_INPUTS[0];
        claimInputs[1] = DUMMY_INPUTS[1];
        claimInputs[2] = DUMMY_INPUTS[2];
        claimInputs[3] = DUMMY_NULLIFIER;

        vm.expectEmit(true, true, false, true);
        emit ShadowChainGame.ArtifactClaimedEvent(gameId, alice, expectedArtifactId, cellIndex, DUMMY_NULLIFIER);

        vm.prank(alice);
        game.claimArtifact(gameId, x, y, DUMMY_PROOF, claimInputs, DUMMY_INVENTORY_COMMITMENT);
    }

    function test_claimArtifact_updatesStats() public {
        uint256 gameId = _createAndStartGame();
        (, bytes32 treasureSeed) = game.getGameMap(gameId);
        (uint8 x, uint8 y) = _findFirstProceduralTreasure(treasureSeed);

        uint8 artifactId = game.getArtifactAtCell(gameId, x, y);
        ArtifactRegistry.Artifact memory art = registry.getArtifact(artifactId);

        ShadowChainGame.Player memory before_ = game.getPlayer(gameId, alice);

        vm.prank(alice);
        game.claimArtifact(gameId, x, y, DUMMY_PROOF, DUMMY_INPUTS, DUMMY_INVENTORY_COMMITMENT);

        ShadowChainGame.Player memory after_ = game.getPlayer(gameId, alice);

        // Stats should be updated by artifact bonuses
        int16 expectedHp = before_.hp + art.hpBonus;
        int8 expectedAtk = before_.attack + art.attackBonus;
        int8 expectedDef = before_.defense + art.defenseBonus;

        // Apply floors
        if (expectedHp < 1) expectedHp = 1;
        if (expectedAtk < 1) expectedAtk = 1;
        if (expectedDef < 0) expectedDef = 0;

        assertEq(after_.hp, expectedHp);
        assertEq(after_.attack, expectedAtk);
        assertEq(after_.defense, expectedDef);
    }

    function test_claimArtifact_invalidCoords_reverts() public {
        uint256 gameId = _createAndStartGame();

        // Coordinates out of bounds should revert
        vm.prank(alice);
        vm.expectRevert("Invalid cell coordinates");
        game.claimArtifact(gameId, 16, 0, DUMMY_PROOF, DUMMY_INPUTS, DUMMY_INVENTORY_COMMITMENT);
    }

    function test_claimArtifact_alreadyClaimed_reverts() public {
        uint256 gameId = _createAndStartGame();
        (, bytes32 treasureSeed) = game.getGameMap(gameId);
        (uint8 x, uint8 y) = _findFirstProceduralTreasure(treasureSeed);

        vm.prank(alice);
        game.claimArtifact(gameId, x, y, DUMMY_PROOF, DUMMY_INPUTS, DUMMY_INVENTORY_COMMITMENT);

        // Bob tries with a different nullifier (to get past nullifier check)
        // but should fail on registry's already claimed check
        bytes32[] memory bobInputs = new bytes32[](4);
        bobInputs[0] = DUMMY_INPUTS[0];
        bobInputs[1] = DUMMY_INPUTS[1];
        bobInputs[2] = DUMMY_INPUTS[2];
        bobInputs[3] = keccak256("bob_nullifier"); // Different nullifier

        vm.prank(bob);
        vm.expectRevert("ArtifactRegistry: already claimed");
        game.claimArtifact(gameId, x, y, DUMMY_PROOF, bobInputs, keccak256("bob_inventory"));
    }
    
    function test_claimArtifact_nullifierReused_reverts() public {
        uint256 gameId = _createAndStartGame();
        (, bytes32 treasureSeed) = game.getGameMap(gameId);
        (uint8 x, uint8 y) = _findFirstProceduralTreasure(treasureSeed);

        vm.prank(alice);
        game.claimArtifact(gameId, x, y, DUMMY_PROOF, DUMMY_INPUTS, DUMMY_INVENTORY_COMMITMENT);

        // Same nullifier should fail even on different cell
        (uint8 x2, uint8 y2) = _findSecondProceduralTreasure(treasureSeed, x, y);
        if (x2 != 255) {
            vm.prank(alice);
            vm.expectRevert("Artifact already claimed");
            game.claimArtifact(gameId, x2, y2, DUMMY_PROOF, DUMMY_INPUTS, keccak256("new_inventory"));
        }
    }

    function test_claimArtifact_gameNotActive_reverts() public {
        uint256 gameId = _createGame();
        _joinGame(gameId, alice, keccak256("alice"));

        vm.prank(alice);
        vm.expectRevert("Game not active");
        game.claimArtifact(gameId, 5, 5, DUMMY_PROOF, DUMMY_INPUTS, DUMMY_INVENTORY_COMMITMENT);
    }

    // =========================================================================
    //                      COMBAT TESTS
    // =========================================================================

    function test_triggerCombat() public {
        uint256 gameId = _createAndStartGame();

        vm.prank(alice);
        game.triggerCombat(gameId, bob, DUMMY_PROOF, DUMMY_INPUTS);

        // Bob should have taken some damage
        ShadowChainGame.Player memory bobP = game.getPlayer(gameId, bob);
        assertTrue(bobP.hp < 100, "Bob should have taken damage");
    }

    function test_triggerCombat_damageApplied() public {
        uint256 gameId = _createAndStartGame();

        ShadowChainGame.Player memory bobBefore = game.getPlayer(gameId, bob);

        vm.prank(alice);
        game.triggerCombat(gameId, bob, DUMMY_PROOF, DUMMY_INPUTS);

        ShadowChainGame.Player memory bobAfter = game.getPlayer(gameId, bob);

        // Bob should have taken damage (attack=10, defense=5, random -3..+3 → damage 2..8)
        assertTrue(bobAfter.hp < bobBefore.hp, "Bob should have taken damage");
        assertTrue(bobAfter.hp >= bobBefore.hp - 8, "Damage should not exceed max");
    }

    function test_triggerCombat_cannotAttackSelf() public {
        uint256 gameId = _createAndStartGame();

        vm.prank(alice);
        vm.expectRevert("Cannot attack self");
        game.triggerCombat(gameId, alice, DUMMY_PROOF, DUMMY_INPUTS);
    }

    function test_triggerCombat_defenderNotAlive_reverts() public {
        uint256 gameId = _createAndStartGame();

        // Bob forfeits
        vm.prank(bob);
        game.forfeit(gameId);

        // Can't attack dead player -- game already resolved since 2-player game
        // Use 4-player game instead
        uint256 gameId2 = _createAndStartFullGame();

        vm.prank(charlie);
        game.forfeit(gameId2);

        vm.prank(alice);
        vm.expectRevert("Defender not alive");
        game.triggerCombat(gameId2, charlie, DUMMY_PROOF, DUMMY_INPUTS);
    }

    function test_triggerCombat_elimination() public {
        uint256 gameId = _createAndStartFullGame();

        // Attack bob repeatedly until eliminated
        // With base stats: attack=10, defense=5, damage = 10-5 + random(-3..+3) = 2..8
        // Bob has 100 HP so need many attacks.
        // Alternatively, we can manipulate block to get consistent results
        ShadowChainGame.Player memory bobP;
        uint256 attackCount = 0;
        while (true) {
            bobP = game.getPlayer(gameId, bob);
            if (bobP.status != ShadowChainGame.PlayerStatus.Alive) break;

            // Roll the block to change random seed each time
            vm.roll(block.number + 1);
            vm.warp(block.timestamp + 1);

            vm.prank(alice);
            game.triggerCombat(gameId, bob, DUMMY_PROOF, DUMMY_INPUTS);
            attackCount++;

            if (attackCount > 100) break; // Safety valve
        }

        bobP = game.getPlayer(gameId, bob);
        assertEq(uint8(bobP.status), uint8(ShadowChainGame.PlayerStatus.Dead));
        assertEq(bobP.hp, int16(0));
    }

    function test_triggerCombat_invalidProof_reverts() public {
        ShadowChainGame strictGame = new ShadowChainGame(
            address(mockVerifier),
            address(mockVerifier),
            address(rejectVerifier),  // combat verifier rejects
            address(registry)
        );

        vm.prank(creator);
        uint256 gameId = strictGame.createGame(SEED, 2, 0);
        vm.prank(alice);
        strictGame.joinGame(gameId, keccak256("alice"), DUMMY_INVENTORY_COMMITMENT);
        vm.prank(bob);
        strictGame.joinGame(gameId, keccak256("bob"), DUMMY_INVENTORY_COMMITMENT);

        vm.prank(alice);
        vm.expectRevert("Invalid combat proof");
        strictGame.triggerCombat(gameId, bob, DUMMY_PROOF, DUMMY_INPUTS);
    }

    // =========================================================================
    //                        FORFEIT TESTS
    // =========================================================================

    function test_forfeit() public {
        uint256 gameId = _createAndStartFullGame();

        vm.prank(alice);
        game.forfeit(gameId);

        ShadowChainGame.Player memory p = game.getPlayer(gameId, alice);
        assertEq(uint8(p.status), uint8(ShadowChainGame.PlayerStatus.Forfeited));

        ShadowChainGame.Game memory g = game.getGame(gameId);
        assertEq(g.aliveCount, 3); // Was 4, now 3
    }

    function test_forfeit_emitsEvent() public {
        uint256 gameId = _createAndStartFullGame();

        vm.expectEmit(true, true, false, true);
        emit ShadowChainGame.PlayerForfeited(gameId, alice, 1);

        vm.prank(alice);
        game.forfeit(gameId);
    }

    function test_forfeit_notAlive_reverts() public {
        uint256 gameId = _createAndStartFullGame();

        vm.prank(alice);
        game.forfeit(gameId);

        vm.prank(alice);
        vm.expectRevert("Player not alive");
        game.forfeit(gameId);
    }

    function test_forfeit_gameNotActive_reverts() public {
        uint256 gameId = _createGame();
        _joinGame(gameId, alice, keccak256("alice"));

        vm.prank(alice);
        vm.expectRevert("Game not active");
        game.forfeit(gameId);
    }

    function test_forfeit_triggersResolution() public {
        uint256 gameId = _createAndStartGame(); // 2 players

        uint256 bobBalBefore = bob.balance;

        vm.prank(alice);
        game.forfeit(gameId);

        // Game should be resolved, bob wins
        ShadowChainGame.Game memory g = game.getGame(gameId);
        assertEq(uint8(g.state), uint8(ShadowChainGame.GameState.Resolved));
        assertEq(g.winner, bob);

        // Bob should have claimable prize (pull-payment pattern)
        assertEq(game.claimablePrizes(bob), ENTRY_FEE * 2);

        // Bob claims prize
        vm.prank(bob);
        game.claimPrize();
        assertEq(bob.balance, bobBalBefore + ENTRY_FEE * 2);
    }

    // =========================================================================
    //                     TURN MANAGEMENT TESTS
    // =========================================================================

    function test_advanceTurn() public {
        uint256 gameId = _createAndStartGame();

        // Warp past turn deadline
        vm.warp(block.timestamp + 61);

        game.advanceTurn(gameId);

        ShadowChainGame.Game memory g = game.getGame(gameId);
        assertEq(g.currentTurn, 2);
        assertTrue(g.turnDeadline > 0);
    }

    function test_advanceTurn_emitsEvent() public {
        uint256 gameId = _createAndStartGame();
        vm.warp(block.timestamp + 61);

        vm.expectEmit(true, false, false, true);
        emit ShadowChainGame.TurnAdvanced(gameId, 2, uint64(block.timestamp + 60));

        game.advanceTurn(gameId);
    }

    function test_advanceTurn_resetsSubmissions() public {
        uint256 gameId = _createAndStartGame();
        bytes32 oldCommitment = keccak256("alice_pos");
        bytes32 newCommitment = keccak256("move1");
        
        // Build inputs before prank (vm.prank only affects next external call)
        bytes32[] memory moveInputs = _buildMoveInputs(oldCommitment, newCommitment, gameId);

        // Alice submits a move
        vm.prank(alice);
        game.submitMove(gameId, newCommitment, DUMMY_PROOF, moveInputs);

        ShadowChainGame.Player memory p1 = game.getPlayer(gameId, alice);
        assertTrue(p1.hasSubmittedThisTurn);

        // Advance turn
        vm.warp(block.timestamp + 61);
        game.advanceTurn(gameId);

        // Submission flag should be reset
        ShadowChainGame.Player memory p2 = game.getPlayer(gameId, alice);
        assertFalse(p2.hasSubmittedThisTurn);
    }

    function test_advanceTurn_tooEarly_reverts() public {
        uint256 gameId = _createAndStartGame();

        vm.expectRevert("Turn not expired");
        game.advanceTurn(gameId);
    }

    function test_advanceTurn_gameNotActive_reverts() public {
        uint256 gameId = _createGame();

        vm.expectRevert("Game not active");
        game.advanceTurn(gameId);
    }

    function test_advanceTurn_triggersResolutionAtMaxTurns() public {
        uint256 gameId = _createAndStartGame();

        uint256 startTime = block.timestamp;

        // Advance through all 50 turns (need 50 advances to go from turn 1 to 51 > maxTurns)
        for (uint32 i = 1; i <= 50; i++) {
            // Warp well past the turn deadline each iteration
            vm.warp(startTime + uint256(i) * 61);
            game.advanceTurn(gameId);

            ShadowChainGame.Game memory gLoop = game.getGame(gameId);
            if (uint8(gLoop.state) == uint8(ShadowChainGame.GameState.Resolved)) break;
        }

        ShadowChainGame.Game memory gResult = game.getGame(gameId);
        assertEq(uint8(gResult.state), uint8(ShadowChainGame.GameState.Resolved));
    }

    function test_advanceTurn_anyoneCanCall() public {
        uint256 gameId = _createAndStartGame();
        vm.warp(block.timestamp + 61);

        // Random address advances the turn (incentive design!)
        address random = makeAddr("random");
        vm.prank(random);
        game.advanceTurn(gameId);

        ShadowChainGame.Game memory g = game.getGame(gameId);
        assertEq(g.currentTurn, 2);
    }

    // =========================================================================
    //                    GAME RESOLUTION TESTS
    // =========================================================================

    function test_resolveGame_byElimination() public {
        uint256 gameId = _createAndStartFullGame();

        uint256 prizeTotal = ENTRY_FEE * 4;
        uint256 aliceBalBefore = alice.balance;

        // Everyone forfeits except alice
        vm.prank(bob);
        game.forfeit(gameId);
        vm.prank(charlie);
        game.forfeit(gameId);
        vm.prank(dave);
        game.forfeit(gameId);

        ShadowChainGame.Game memory g = game.getGame(gameId);
        assertEq(uint8(g.state), uint8(ShadowChainGame.GameState.Resolved));
        assertEq(g.winner, alice);
        assertEq(g.prizePool, 0);

        // Prize is claimable (pull-payment pattern)
        assertEq(game.claimablePrizes(alice), prizeTotal);

        // Alice claims prize
        vm.prank(alice);
        game.claimPrize();
        assertEq(alice.balance, aliceBalBefore + prizeTotal);
    }

    function test_resolveGame_emitsEvent() public {
        uint256 gameId = _createAndStartGame();

        vm.expectEmit(true, true, false, true);
        emit ShadowChainGame.GameResolved(gameId, bob, ENTRY_FEE * 2);

        vm.prank(alice);
        game.forfeit(gameId);
    }

    function test_resolveGame_byScore() public {
        uint256 gameId = _createAndStartGame();

        uint256 startTime = block.timestamp;

        // Advance to max turns
        for (uint32 i = 1; i <= 50; i++) {
            vm.warp(startTime + uint256(i) * 61);
            game.advanceTurn(gameId);

            ShadowChainGame.Game memory gLoop = game.getGame(gameId);
            if (uint8(gLoop.state) == uint8(ShadowChainGame.GameState.Resolved)) break;
        }

        ShadowChainGame.Game memory gFinal = game.getGame(gameId);
        assertEq(uint8(gFinal.state), uint8(ShadowChainGame.GameState.Resolved));
        assertTrue(gFinal.winner != address(0), "Should have a winner");
    }

    function test_resolveGame_manualResolve() public {
        uint256 gameId = _createAndStartFullGame();

        // Eliminate until 1 left
        vm.prank(bob);
        game.forfeit(gameId);
        vm.prank(charlie);
        game.forfeit(gameId);

        // Still 2 alive (alice and dave), can't resolve yet
        vm.expectRevert("Cannot resolve yet");
        game.resolveGame(gameId);

        vm.prank(dave);
        game.forfeit(gameId);

        // Now resolved (auto-triggered by forfeit when aliveCount==1)
        ShadowChainGame.Game memory g = game.getGame(gameId);
        assertEq(uint8(g.state), uint8(ShadowChainGame.GameState.Resolved));
    }

    function test_resolveGame_prizeTransfer() public {
        uint256 gameId = _createAndStartGame();

        uint256 expectedPrize = ENTRY_FEE * 2;
        uint256 bobBalBefore = bob.balance;

        vm.prank(alice);
        game.forfeit(gameId);

        // Prize is claimable (pull-payment pattern)
        assertEq(game.claimablePrizes(bob), expectedPrize);

        // Bob claims prize
        vm.prank(bob);
        game.claimPrize();
        assertEq(bob.balance, bobBalBefore + expectedPrize);
    }

    function test_resolveGame_freeGame() public {
        vm.prank(creator);
        uint256 gameId = game.createGame(SEED, 2, 0);
        _joinFreeGame(gameId, alice, keccak256("alice"));
        _joinFreeGame(gameId, bob, keccak256("bob"));

        uint256 bobBalBefore = bob.balance;

        vm.prank(alice);
        game.forfeit(gameId);

        // No prize to transfer
        assertEq(bob.balance, bobBalBefore);

        ShadowChainGame.Game memory g = game.getGame(gameId);
        assertEq(uint8(g.state), uint8(ShadowChainGame.GameState.Resolved));
        assertEq(g.winner, bob);
    }

    // =========================================================================
    //                      VIEW FUNCTION TESTS
    // =========================================================================

    function test_getGame() public {
        uint256 gameId = _createGame();
        ShadowChainGame.Game memory g = game.getGame(gameId);
        assertEq(g.id, gameId);
        assertEq(g.seed, SEED);
    }

    function test_getPlayer() public {
        uint256 gameId = _createGame();
        _joinGame(gameId, alice, keccak256("alice"));

        ShadowChainGame.Player memory p = game.getPlayer(gameId, alice);
        assertEq(p.addr, alice);
    }

    function test_isWall() public {
        uint256 gameId = _createGame();
        // Spawn point (0,0) should never be a wall
        assertFalse(game.isWall(gameId, 0, 0));
    }

    function test_isTreasure() public {
        uint256 gameId = _createGame();
        // Spawn point should never be a treasure
        assertFalse(game.isTreasure(gameId, 0, 0));
    }

    function test_getGameMap() public {
        uint256 gameId = _createGame();
        (uint256 w, bytes32 treasureSeed) = game.getGameMap(gameId);
        (uint256 ew, ) = MapGenerator.getMap(SEED);
        assertEq(w, ew);
        assertEq(treasureSeed, bytes32(0), "TreasureSeed should be 0 before game starts");
    }

    // =========================================================================
    //                    MULTI-TURN INTEGRATION TEST
    // =========================================================================

    function test_fullGameLifecycle() public {
        // Create game
        vm.prank(creator);
        uint256 gameId = game.createGame(SEED, 2, ENTRY_FEE);

        // Set map hash before players join
        vm.prank(creator);
        game.setMapHash(gameId, keccak256("map_hash"));

        // Both players join with known commitments
        bytes32 aliceCommit = keccak256("alice_start");
        bytes32 bobCommit = keccak256("bob_start");
        vm.prank(alice);
        game.joinGame{value: ENTRY_FEE}(gameId, aliceCommit, DUMMY_INVENTORY_COMMITMENT);
        vm.prank(bob);
        game.joinGame{value: ENTRY_FEE}(gameId, bobCommit, DUMMY_INVENTORY_COMMITMENT);

        // Game should be active
        ShadowChainGame.Game memory g = game.getGame(gameId);
        assertEq(uint8(g.state), uint8(ShadowChainGame.GameState.Active));

        // Turn 1: Both players submit moves
        bytes32 aliceT1 = keccak256("alice_t1");
        bytes32 bobT1 = keccak256("bob_t1");
        
        // Build inputs before prank
        bytes32[] memory aliceT1Inputs = _buildMoveInputs(aliceCommit, aliceT1, gameId);
        bytes32[] memory bobT1Inputs = _buildMoveInputs(bobCommit, bobT1, gameId);
        
        vm.prank(alice);
        game.submitMove(gameId, aliceT1, DUMMY_PROOF, aliceT1Inputs);
        vm.prank(bob);
        game.submitMove(gameId, bobT1, DUMMY_PROOF, bobT1Inputs);

        // Advance to turn 2
        vm.warp(block.timestamp + 61);
        game.advanceTurn(gameId);

        g = game.getGame(gameId);
        assertEq(g.currentTurn, 2);

        // Turn 2: Alice claims an artifact
        (, bytes32 treasureSeed) = game.getGameMap(gameId);
        (uint8 tx, uint8 ty) = _findFirstProceduralTreasure(treasureSeed);
        if (tx != 255) {
            // Use a different nullifier for claim_artifact
            bytes32[] memory claimInputs = new bytes32[](4);
            claimInputs[0] = DUMMY_INPUTS[0];
            claimInputs[1] = DUMMY_INPUTS[1];
            claimInputs[2] = DUMMY_INPUTS[2];
            claimInputs[3] = DUMMY_NULLIFIER;
            vm.prank(alice);
            game.claimArtifact(gameId, tx, ty, DUMMY_PROOF, claimInputs, keccak256("alice_new_inventory"));
        }

        // Turn 2: Bob submits a move
        bytes32 bobT2 = keccak256("bob_t2");
        bytes32[] memory bobT2Inputs = _buildMoveInputs(bobT1, bobT2, gameId);
        vm.prank(bob);
        game.submitMove(gameId, bobT2, DUMMY_PROOF, bobT2Inputs);

        // Update alice's inventory commitment for combat (if she claimed artifact)
        // Note: claimArtifact updates it, so we need matching inputs
        bytes32[] memory combatInputs = new bytes32[](4);
        combatInputs[0] = DUMMY_INPUTS[0];
        combatInputs[1] = DUMMY_INPUTS[1];
        combatInputs[2] = DUMMY_INPUTS[2];
        combatInputs[3] = tx != 255 ? keccak256("alice_new_inventory") : DUMMY_INVENTORY_COMMITMENT;
        
        // Alice triggers combat
        vm.roll(block.number + 1);
        vm.prank(alice);
        game.triggerCombat(gameId, bob, DUMMY_PROOF, combatInputs);

        // Bob forfeits, alice wins
        vm.prank(bob);
        game.forfeit(gameId);

        g = game.getGame(gameId);
        assertEq(uint8(g.state), uint8(ShadowChainGame.GameState.Resolved));
        assertEq(g.winner, alice);
    }

    // =========================================================================
    //                    EDGE CASE TESTS
    // =========================================================================

    function test_multipleGamesSimultaneous() public {
        vm.prank(creator);
        uint256 g1 = game.createGame(1, 2, ENTRY_FEE);
        vm.prank(creator);
        uint256 g2 = game.createGame(2, 2, ENTRY_FEE);

        // Join both games
        vm.prank(alice);
        game.joinGame{value: ENTRY_FEE}(g1, keccak256("a1"), DUMMY_INVENTORY_COMMITMENT);
        vm.prank(alice);
        game.joinGame{value: ENTRY_FEE}(g2, keccak256("a2"), DUMMY_INVENTORY_COMMITMENT);

        vm.prank(bob);
        game.joinGame{value: ENTRY_FEE}(g1, keccak256("b1"), DUMMY_INVENTORY_COMMITMENT);
        vm.prank(bob);
        game.joinGame{value: ENTRY_FEE}(g2, keccak256("b2"), DUMMY_INVENTORY_COMMITMENT);

        // Both games active
        assertEq(uint8(game.getGame(g1).state), uint8(ShadowChainGame.GameState.Active));
        assertEq(uint8(game.getGame(g2).state), uint8(ShadowChainGame.GameState.Active));

        // Resolve game 1
        vm.prank(alice);
        game.forfeit(g1);
        assertEq(uint8(game.getGame(g1).state), uint8(ShadowChainGame.GameState.Resolved));

        // Game 2 still active
        assertEq(uint8(game.getGame(g2).state), uint8(ShadowChainGame.GameState.Active));
    }

    function test_receiveEth() public {
        // Game contract should accept ETH
        (bool success,) = address(game).call{value: 1 ether}("");
        assertTrue(success);
    }

    // =========================================================================
    //                        INTERNAL HELPERS
    // =========================================================================

    function _findFirstTreasureCell(uint256 bitmap) internal pure returns (uint8) {
        for (uint16 i = 0; i < 256; i++) {
            if ((bitmap >> i) & 1 == 1) return uint8(i);
        }
        return 255; // Not found
    }
    
    /// @notice Find first treasure cell using procedural generation (Poseidon)
    function _findFirstProceduralTreasure(bytes32 treasureSeed) internal pure returns (uint8 x, uint8 y) {
        for (uint8 _y = 0; _y < 16; _y++) {
            for (uint8 _x = 0; _x < 16; _x++) {
                // Use keccak256 to match contract's isTreasure()
                bytes32 cellHash = keccak256(abi.encodePacked(_x, _y, treasureSeed));
                if (uint256(cellHash) % 256 < 20) { // TREASURE_THRESHOLD = 20
                    return (_x, _y);
                }
            }
        }
        return (255, 255); // Not found (unlikely with threshold 20)
    }
    
    /// @notice Find second treasure cell (different from first)
    function _findSecondProceduralTreasure(bytes32 treasureSeed, uint8 skipX, uint8 skipY) internal pure returns (uint8 x, uint8 y) {
        for (uint8 _y = 0; _y < 16; _y++) {
            for (uint8 _x = 0; _x < 16; _x++) {
                if (_x == skipX && _y == skipY) continue;
                bytes32 cellHash = keccak256(abi.encodePacked(_x, _y, treasureSeed));
                if (uint256(cellHash) % 256 < 20) {
                    return (_x, _y);
                }
            }
        }
        return (255, 255);
    }
}
