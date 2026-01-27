// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title MapGenerator
/// @notice Pure library that generates a 16x16 dungeon grid deterministically from a seed.
///         The grid is encoded as two uint256 bitmaps (256 bits = 16x16 cells):
///           - wallBitmap:     bit i = 1 means cell i is a wall
///           - treasureBitmap: bit i = 1 means cell i is a treasure cell
///         Cell index = y * 16 + x  (x = column, y = row, both 0-15)
///
///         Design rules:
///           - Four spawn points at corners (0,0), (15,0), (0,15), (15,15) are always passable
///           - Spawn adjacent cells are also passable (ensures players can move)
///           - ~30% of interior cells are walls (deterministic from seed)
///           - 5-8 treasure cells placed on passable cells away from spawns
///           - Border edges have some walls to create chokepoints
library MapGenerator {
    uint8 constant GRID_SIZE = 16;
    uint8 constant TOTAL_CELLS = 255; // max index (0-255)

    // Spawn point coordinates (corners)
    // Spawn 0: (0,0)   Spawn 1: (15,0)
    // Spawn 2: (0,15)  Spawn 3: (15,15)

    /// @notice Get the cell index from (x, y) coordinates
    /// @param x Column (0-15)
    /// @param y Row (0-15)
    /// @return Cell index (0-255)
    function cellIndex(uint8 x, uint8 y) internal pure returns (uint8) {
        return y * GRID_SIZE + x;
    }

    /// @notice Generate the full map from a seed
    /// @param seed Seed value (e.g., blockhash cast to uint256)
    /// @return wallBitmap Bitmap where bit i = 1 means cell i is a wall
    /// @return treasureBitmap Bitmap where bit i = 1 means cell i is a treasure cell
    function getMap(uint256 seed) internal pure returns (uint256 wallBitmap, uint256 treasureBitmap) {
        wallBitmap = _generateWalls(seed);
        treasureBitmap = _generateTreasures(seed, wallBitmap);
    }

    /// @notice Query a single cell's properties
    /// @param seed The map seed
    /// @param x Column (0-15)
    /// @param y Row (0-15)
    /// @return isWall True if the cell is a wall
    /// @return isTreasure True if the cell is a treasure cell
    function getCell(uint256 seed, uint8 x, uint8 y) internal pure returns (bool isWall, bool isTreasure) {
        require(x < GRID_SIZE && y < GRID_SIZE, "MapGenerator: out of bounds");
        (uint256 walls, uint256 treasures) = getMap(seed);
        uint8 idx = cellIndex(x, y);
        isWall = (walls >> idx) & 1 == 1;
        isTreasure = (treasures >> idx) & 1 == 1;
    }

    /// @notice Check if coordinates are a spawn point
    /// @param x Column
    /// @param y Row
    /// @return True if (x,y) is a spawn point
    function isSpawnPoint(uint8 x, uint8 y) internal pure returns (bool) {
        return (x == 0 || x == 15) && (y == 0 || y == 15);
    }

    /// @notice Get spawn point coordinates for a given player index (0-3)
    /// @param index Player spawn index (0-3, wraps for >4 players)
    /// @return x Column
    /// @return y Row
    function getSpawnPoint(uint8 index) internal pure returns (uint8 x, uint8 y) {
        uint8 i = index % 4;
        if (i == 0) return (0, 0);
        if (i == 1) return (15, 0);
        if (i == 2) return (0, 15);
        return (15, 15);
    }

    // =========================================================================
    //                           INTERNAL HELPERS
    // =========================================================================

    /// @dev Generate wall bitmap. ~30% walls, avoiding spawn zones.
    function _generateWalls(uint256 seed) private pure returns (uint256 walls) {
        for (uint8 y = 0; y < GRID_SIZE; y++) {
            for (uint8 x = 0; x < GRID_SIZE; x++) {
                uint8 idx = cellIndex(x, y);

                // Never place walls on spawn points or their direct neighbors
                if (_isSpawnZone(x, y)) continue;

                // Deterministic pseudo-random per cell
                uint256 cellHash = uint256(keccak256(abi.encodePacked(seed, x, y, "wall")));

                // ~30% wall chance
                if (cellHash % 100 < 30) {
                    walls |= (1 << idx);
                }
            }
        }
    }

    /// @dev Generate treasure bitmap. 6 treasures placed on non-wall, non-spawn cells.
    function _generateTreasures(uint256 seed, uint256 wallBitmap) private pure returns (uint256 treasures) {
        uint8 placed = 0;
        uint8 maxTreasures = 6;

        // Iterate with a shuffled ordering derived from seed
        for (uint16 attempt = 0; attempt < 256 && placed < maxTreasures; attempt++) {
            uint256 h = uint256(keccak256(abi.encodePacked(seed, attempt, "treasure")));
            uint8 x = uint8(h % GRID_SIZE);
            uint8 y = uint8((h >> 8) % GRID_SIZE);
            uint8 idx = cellIndex(x, y);

            // Skip if wall, spawn zone, or already a treasure
            if ((wallBitmap >> idx) & 1 == 1) continue;
            if (_isSpawnZone(x, y)) continue;
            if ((treasures >> idx) & 1 == 1) continue;

            treasures |= (1 << idx);
            placed++;
        }
    }

    /// @dev Check if a cell is in a spawn zone (spawn point or adjacent to one).
    ///      This creates a 2x2 safe area in each corner.
    function _isSpawnZone(uint8 x, uint8 y) private pure returns (bool) {
        // Corner (0,0): x<=1 && y<=1
        if (x <= 1 && y <= 1) return true;
        // Corner (15,0): x>=14 && y<=1
        if (x >= 14 && y <= 1) return true;
        // Corner (0,15): x<=1 && y>=14
        if (x <= 1 && y >= 14) return true;
        // Corner (15,15): x>=14 && y>=14
        if (x >= 14 && y >= 14) return true;
        return false;
    }
}
