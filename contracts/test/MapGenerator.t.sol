// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {MapGenerator} from "../src/MapGenerator.sol";

/// @dev Wrapper contract so library reverts happen at a sub-call depth,
///      letting vm.expectRevert work properly.
contract MapGeneratorWrapper {
    function getCell(uint256 seed, uint8 x, uint8 y) external pure returns (bool isWall, bool isTreasure) {
        return MapGenerator.getCell(seed, x, y);
    }
}

contract MapGeneratorTest is Test {
    using MapGenerator for uint256;

    MapGeneratorWrapper wrapper;

    function setUp() public {
        wrapper = new MapGeneratorWrapper();
    }

    // =========================================================================
    //                         DETERMINISM TESTS
    // =========================================================================

    function test_sameSeadProducesSameMap() public pure {
        uint256 seed = 42;
        (uint256 walls1, uint256 treasures1) = MapGenerator.getMap(seed);
        (uint256 walls2, uint256 treasures2) = MapGenerator.getMap(seed);
        assertEq(walls1, walls2, "Wall bitmaps should match");
        assertEq(treasures1, treasures2, "Treasure bitmaps should match");
    }

    function test_differentSeedsProduceDifferentMaps() public pure {
        (uint256 walls1,) = MapGenerator.getMap(1);
        (uint256 walls2,) = MapGenerator.getMap(2);
        assertTrue(walls1 != walls2, "Different seeds should produce different maps");
    }

    function testFuzz_deterministicGeneration(uint256 seed) public pure {
        (uint256 w1, uint256 t1) = MapGenerator.getMap(seed);
        (uint256 w2, uint256 t2) = MapGenerator.getMap(seed);
        assertEq(w1, w2);
        assertEq(t1, t2);
    }

    // =========================================================================
    //                       SPAWN POINT TESTS
    // =========================================================================

    function test_spawnPointsArePassable() public pure {
        uint256 seed = 12345;
        (uint256 walls,) = MapGenerator.getMap(seed);

        // Check all 4 corners
        uint8[4] memory xs = [0, 15, 0, 15];
        uint8[4] memory ys = [0, 0, 15, 15];

        for (uint8 i = 0; i < 4; i++) {
            uint8 idx = MapGenerator.cellIndex(xs[i], ys[i]);
            assertEq((walls >> idx) & 1, 0, "Spawn point should not be a wall");
        }
    }

    function test_spawnZonesArePassable() public pure {
        uint256 seed = 99999;
        (uint256 walls,) = MapGenerator.getMap(seed);

        // Check 2x2 zones around each corner
        // Corner (0,0): cells (0,0), (1,0), (0,1), (1,1)
        for (uint8 y = 0; y < 2; y++) {
            for (uint8 x = 0; x < 2; x++) {
                uint8 idx = MapGenerator.cellIndex(x, y);
                assertEq((walls >> idx) & 1, 0, "Spawn zone should be passable");
            }
        }
    }

    function testFuzz_spawnPointsAlwaysPassable(uint256 seed) public pure {
        (uint256 walls,) = MapGenerator.getMap(seed);

        // All 4 spawn points
        assertEq((walls >> MapGenerator.cellIndex(0, 0)) & 1, 0);
        assertEq((walls >> MapGenerator.cellIndex(15, 0)) & 1, 0);
        assertEq((walls >> MapGenerator.cellIndex(0, 15)) & 1, 0);
        assertEq((walls >> MapGenerator.cellIndex(15, 15)) & 1, 0);
    }

    // =========================================================================
    //                        SPAWN POINT HELPERS
    // =========================================================================

    function test_isSpawnPoint() public pure {
        assertTrue(MapGenerator.isSpawnPoint(0, 0));
        assertTrue(MapGenerator.isSpawnPoint(15, 0));
        assertTrue(MapGenerator.isSpawnPoint(0, 15));
        assertTrue(MapGenerator.isSpawnPoint(15, 15));
        assertFalse(MapGenerator.isSpawnPoint(7, 7));
        assertFalse(MapGenerator.isSpawnPoint(1, 0));
    }

    function test_getSpawnPoint() public pure {
        (uint8 x0, uint8 y0) = MapGenerator.getSpawnPoint(0);
        assertEq(x0, 0);
        assertEq(y0, 0);

        (uint8 x1, uint8 y1) = MapGenerator.getSpawnPoint(1);
        assertEq(x1, 15);
        assertEq(y1, 0);

        (uint8 x2, uint8 y2) = MapGenerator.getSpawnPoint(2);
        assertEq(x2, 0);
        assertEq(y2, 15);

        (uint8 x3, uint8 y3) = MapGenerator.getSpawnPoint(3);
        assertEq(x3, 15);
        assertEq(y3, 15);

        // Wraps for index >= 4
        (uint8 x4, uint8 y4) = MapGenerator.getSpawnPoint(4);
        assertEq(x4, 0);
        assertEq(y4, 0);
    }

    // =========================================================================
    //                       TREASURE TESTS
    // =========================================================================

    function test_treasuresNotOnWalls() public pure {
        uint256 seed = 777;
        (uint256 walls, uint256 treasures) = MapGenerator.getMap(seed);

        // No cell should be both a wall and a treasure
        assertEq(walls & treasures, 0, "No cell should be both wall and treasure");
    }

    function test_treasuresNotInSpawnZones() public pure {
        uint256 seed = 555;
        (, uint256 treasures) = MapGenerator.getMap(seed);

        // Check no treasures in spawn zones
        for (uint8 y = 0; y < 2; y++) {
            for (uint8 x = 0; x < 2; x++) {
                assertEq((treasures >> MapGenerator.cellIndex(x, y)) & 1, 0);
                assertEq((treasures >> MapGenerator.cellIndex(14 + x, y)) & 1, 0);
                assertEq((treasures >> MapGenerator.cellIndex(x, 14 + y)) & 1, 0);
                assertEq((treasures >> MapGenerator.cellIndex(14 + x, 14 + y)) & 1, 0);
            }
        }
    }

    function test_treasureCount() public pure {
        uint256 seed = 333;
        (, uint256 treasures) = MapGenerator.getMap(seed);

        uint8 count = 0;
        for (uint16 i = 0; i < 256; i++) {
            if ((treasures >> i) & 1 == 1) count++;
        }

        // Should have 6 treasures (or fewer if generation couldn't place all)
        assertTrue(count > 0 && count <= 6, "Should have 1-6 treasures");
    }

    function testFuzz_treasuresNeverOnWalls(uint256 seed) public pure {
        (uint256 walls, uint256 treasures) = MapGenerator.getMap(seed);
        assertEq(walls & treasures, 0, "Treasures must not overlap walls");
    }

    // =========================================================================
    //                       GETCEL TESTS
    // =========================================================================

    function test_getCellMatchesBitmap() public pure {
        uint256 seed = 42;
        (uint256 walls, uint256 treasures) = MapGenerator.getMap(seed);

        for (uint8 y = 0; y < 16; y++) {
            for (uint8 x = 0; x < 16; x++) {
                (bool isWall, bool isTreasure) = MapGenerator.getCell(seed, x, y);
                uint8 idx = MapGenerator.cellIndex(x, y);

                assertEq(isWall, (walls >> idx) & 1 == 1, "Wall mismatch");
                assertEq(isTreasure, (treasures >> idx) & 1 == 1, "Treasure mismatch");
            }
        }
    }

    function test_getCellOutOfBoundsReverts() public {
        vm.expectRevert("MapGenerator: out of bounds");
        wrapper.getCell(42, 16, 0);

        vm.expectRevert("MapGenerator: out of bounds");
        wrapper.getCell(42, 0, 16);
    }

    // =========================================================================
    //                       WALL DENSITY TEST
    // =========================================================================

    function test_wallDensityReasonable() public pure {
        uint256 seed = 42;
        (uint256 walls,) = MapGenerator.getMap(seed);

        uint16 wallCount = 0;
        for (uint16 i = 0; i < 256; i++) {
            if ((walls >> i) & 1 == 1) wallCount++;
        }

        // Should be roughly 30% of non-spawn-zone cells (~240 eligible * 0.3 = ~72)
        // Allow a wide range for randomness
        assertTrue(wallCount > 20, "Too few walls");
        assertTrue(wallCount < 120, "Too many walls");
    }

    // =========================================================================
    //                       CELL INDEX TEST
    // =========================================================================

    function test_cellIndex() public pure {
        assertEq(MapGenerator.cellIndex(0, 0), 0);
        assertEq(MapGenerator.cellIndex(15, 0), 15);
        assertEq(MapGenerator.cellIndex(0, 1), 16);
        assertEq(MapGenerator.cellIndex(15, 15), 255);
        assertEq(MapGenerator.cellIndex(7, 7), 7 * 16 + 7);
    }

    // =========================================================================
    //                     GAS BENCHMARK
    // =========================================================================

    function test_gasUsage() public view {
        uint256 gasBefore = gasleft();
        MapGenerator.getMap(42);
        uint256 gasUsed = gasBefore - gasleft();
        console2.log("MapGenerator.getMap gas:", gasUsed);
        // Should be reasonable — log it
    }
}
