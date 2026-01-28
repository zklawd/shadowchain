// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ArtifactRegistry
/// @notice Defines artifact types and stat modifiers for the ShadowChain game.
///         Artifacts are placed at treasure cells on the map. When a player proves
///         they are standing on a treasure cell, they claim the artifact and gain
///         permanent stat bonuses for that game.
///
///         Artifact assignment to treasure cells is deterministic from the game seed.
contract ArtifactRegistry {
    // =========================================================================
    //                                TYPES
    // =========================================================================

    struct Artifact {
        uint8 id;
        string name;
        int8 attackBonus;
        int8 defenseBonus;
        int16 hpBonus;
    }

    // =========================================================================
    //                              CONSTANTS
    // =========================================================================

    uint8 public constant NUM_ARTIFACTS = 8;

    // Base player stats
    int16 public constant BASE_HP = 100;
    int8 public constant BASE_ATTACK = 10;
    int8 public constant BASE_DEFENSE = 5;

    // =========================================================================
    //                               EVENTS
    // =========================================================================

    /// @notice Emitted when a player claims an artifact in a game
    event ArtifactClaimed(
        uint256 indexed gameId,
        address indexed player,
        uint8 artifactId,
        uint8 treasureCellIndex
    );

    // =========================================================================
    //                               STATE
    // =========================================================================

    /// @notice gameId → treasureCellIndex → claiming player (address(0) = unclaimed)
    mapping(uint256 => mapping(uint8 => address)) public claimedBy;

    /// @notice gameId → treasureCellIndex → artifact ID assigned to that cell
    mapping(uint256 => mapping(uint8 => uint8)) public cellArtifact;

    /// @notice gameId → player → list of artifact IDs they hold
    mapping(uint256 => mapping(address => uint8[])) public playerArtifacts;

    // =========================================================================
    //                          ARTIFACT DEFINITIONS
    // =========================================================================

    /// @notice Get artifact definition by ID (1-indexed, 0 = none)
    /// @param id Artifact ID (1-8)
    /// @return artifact The artifact struct
    function getArtifact(uint8 id) public pure returns (Artifact memory artifact) {
        require(id >= 1 && id <= NUM_ARTIFACTS, "ArtifactRegistry: invalid artifact ID");

        if (id == 1) return Artifact(1, "Shadow Blade",     5,  0,   0);
        if (id == 2) return Artifact(2, "Iron Aegis",       0,  5,   0);
        if (id == 3) return Artifact(3, "Vitality Amulet",  0,  0,  20);
        if (id == 4) return Artifact(4, "Berserker Helm",   8, -2,   0);
        if (id == 5) return Artifact(5, "Phantom Cloak",   -1,  7,  10);
        if (id == 6) return Artifact(6, "War Gauntlets",    3,  3,   0);
        if (id == 7) return Artifact(7, "Blood Crystal",    6,  0, -10);
        if (id == 8) return Artifact(8, "Soul Vessel",      2,  2,  15);

        revert("unreachable");
    }

    /// @notice Get all artifact definitions
    /// @return artifacts Array of all 8 artifacts
    function getAllArtifacts() external pure returns (Artifact[] memory artifacts) {
        artifacts = new Artifact[](NUM_ARTIFACTS);
        for (uint8 i = 1; i <= NUM_ARTIFACTS; i++) {
            artifacts[i - 1] = getArtifact(i);
        }
    }

    // =========================================================================
    //                        ARTIFACT ASSIGNMENT
    // =========================================================================

    /// @notice Assign artifacts to treasure cells for a game. Called once at game creation.
    /// @param gameId The game ID
    /// @param seed The game seed
    /// @param treasureCellIndices Array of cell indices that are treasure cells
    function assignArtifacts(
        uint256 gameId,
        uint256 seed,
        uint8[] calldata treasureCellIndices
    ) external {
        for (uint256 i = 0; i < treasureCellIndices.length; i++) {
            // Deterministic artifact assignment from seed + cell position
            uint256 h = uint256(keccak256(abi.encodePacked(seed, treasureCellIndices[i], "artifact")));
            uint8 artifactId = uint8((h % NUM_ARTIFACTS) + 1); // 1-indexed
            cellArtifact[gameId][treasureCellIndices[i]] = artifactId;
        }
    }

    /// @notice Record an artifact claim by a player (legacy: uses pre-assigned artifacts)
    /// @param gameId The game ID
    /// @param player The claiming player's address
    /// @param treasureCellIndex The cell index of the treasure
    /// @return artifactId The ID of the claimed artifact
    function claimArtifact(
        uint256 gameId,
        address player,
        uint8 treasureCellIndex
    ) external returns (uint8 artifactId) {
        require(claimedBy[gameId][treasureCellIndex] == address(0), "ArtifactRegistry: already claimed");

        artifactId = cellArtifact[gameId][treasureCellIndex];
        require(artifactId != 0, "ArtifactRegistry: no artifact at cell");

        claimedBy[gameId][treasureCellIndex] = player;
        playerArtifacts[gameId][player].push(artifactId);

        emit ArtifactClaimed(gameId, player, artifactId, treasureCellIndex);
    }
    
    /// @notice Record an artifact claim with procedurally generated artifact ID
    /// @param gameId The game ID
    /// @param player The claiming player's address
    /// @param cellIndex The cell index (y * 16 + x)
    /// @param artifactId The artifact ID (derived from treasureSeed by caller)
    function claimArtifactProcedural(
        uint256 gameId,
        address player,
        uint8 cellIndex,
        uint8 artifactId
    ) external {
        require(claimedBy[gameId][cellIndex] == address(0), "ArtifactRegistry: already claimed");
        require(artifactId >= 1 && artifactId <= NUM_ARTIFACTS, "ArtifactRegistry: invalid artifact ID");

        claimedBy[gameId][cellIndex] = player;
        playerArtifacts[gameId][player].push(artifactId);

        emit ArtifactClaimed(gameId, player, artifactId, cellIndex);
    }

    // =========================================================================
    //                          STAT COMPUTATION
    // =========================================================================

    /// @notice Compute a player's total stats including artifact bonuses
    /// @param gameId The game ID
    /// @param player The player's address
    /// @return hp Total HP
    /// @return attack Total attack
    /// @return defense Total defense
    function getPlayerStats(
        uint256 gameId,
        address player
    ) external view returns (int16 hp, int8 attack, int8 defense) {
        hp = BASE_HP;
        attack = BASE_ATTACK;
        defense = BASE_DEFENSE;

        uint8[] storage arts = playerArtifacts[gameId][player];
        for (uint256 i = 0; i < arts.length; i++) {
            Artifact memory a = getArtifact(arts[i]);
            hp += a.hpBonus;
            attack += a.attackBonus;
            defense += a.defenseBonus;
        }

        // Floor stats at 1 (can't go negative)
        if (hp < 1) hp = 1;
        if (attack < 1) attack = 1;
        if (defense < 0) defense = 0;
    }

    /// @notice Get the artifact IDs held by a player in a game
    /// @param gameId The game ID
    /// @param player The player's address
    /// @return Array of artifact IDs
    function getPlayerArtifactIds(
        uint256 gameId,
        address player
    ) external view returns (uint8[] memory) {
        return playerArtifacts[gameId][player];
    }
}
