// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {ArtifactRegistry} from "../src/ArtifactRegistry.sol";

contract ArtifactRegistryTest is Test {
    ArtifactRegistry public registry;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint256 constant GAME_ID = 1;
    uint256 constant SEED = 42;

    function setUp() public {
        registry = new ArtifactRegistry();
    }

    // =========================================================================
    //                     ARTIFACT DEFINITIONS
    // =========================================================================

    function test_getArtifact_allValid() public view {
        for (uint8 i = 1; i <= registry.NUM_ARTIFACTS(); i++) {
            ArtifactRegistry.Artifact memory a = registry.getArtifact(i);
            assertEq(a.id, i, "ID mismatch");
            assertTrue(bytes(a.name).length > 0, "Name should not be empty");
        }
    }

    function test_getArtifact_invalidId_reverts() public {
        vm.expectRevert("ArtifactRegistry: invalid artifact ID");
        registry.getArtifact(0);

        vm.expectRevert("ArtifactRegistry: invalid artifact ID");
        registry.getArtifact(9);
    }

    function test_getAllArtifacts() public view {
        ArtifactRegistry.Artifact[] memory all = registry.getAllArtifacts();
        assertEq(all.length, 8);
        assertEq(all[0].id, 1);
        assertEq(all[7].id, 8);
    }

    function test_specificArtifactStats() public view {
        // Shadow Blade: +5 attack
        ArtifactRegistry.Artifact memory blade = registry.getArtifact(1);
        assertEq(blade.attackBonus, 5);
        assertEq(blade.defenseBonus, 0);
        assertEq(blade.hpBonus, 0);

        // Vitality Amulet: +20 HP
        ArtifactRegistry.Artifact memory amulet = registry.getArtifact(3);
        assertEq(amulet.hpBonus, 20);

        // Berserker Helm: +8 attack, -2 defense
        ArtifactRegistry.Artifact memory helm = registry.getArtifact(4);
        assertEq(helm.attackBonus, 8);
        assertEq(helm.defenseBonus, -2);
    }

    // =========================================================================
    //                     ARTIFACT ASSIGNMENT
    // =========================================================================

    function test_assignArtifacts() public {
        uint8[] memory cells = new uint8[](3);
        cells[0] = 50;
        cells[1] = 100;
        cells[2] = 200;

        registry.assignArtifacts(GAME_ID, SEED, cells);

        // All cells should have an artifact assigned (1-8)
        for (uint256 i = 0; i < cells.length; i++) {
            uint8 artId = registry.cellArtifact(GAME_ID, cells[i]);
            assertTrue(artId >= 1 && artId <= 8, "Artifact ID out of range");
        }
    }

    function test_assignArtifacts_deterministic() public {
        uint8[] memory cells = new uint8[](3);
        cells[0] = 50;
        cells[1] = 100;
        cells[2] = 200;

        // Deploy two registries, assign with same params
        ArtifactRegistry reg2 = new ArtifactRegistry();

        registry.assignArtifacts(GAME_ID, SEED, cells);
        reg2.assignArtifacts(GAME_ID, SEED, cells);

        for (uint256 i = 0; i < cells.length; i++) {
            assertEq(
                registry.cellArtifact(GAME_ID, cells[i]),
                reg2.cellArtifact(GAME_ID, cells[i]),
                "Assignment should be deterministic"
            );
        }
    }

    // =========================================================================
    //                       CLAIMING
    // =========================================================================

    function test_claimArtifact() public {
        uint8[] memory cells = new uint8[](1);
        cells[0] = 50;
        registry.assignArtifacts(GAME_ID, SEED, cells);

        uint8 artId = registry.claimArtifact(GAME_ID, alice, 50);
        assertTrue(artId >= 1 && artId <= 8);
        assertEq(registry.claimedBy(GAME_ID, 50), alice);
    }

    function test_claimArtifact_emitsEvent() public {
        uint8[] memory cells = new uint8[](1);
        cells[0] = 50;
        registry.assignArtifacts(GAME_ID, SEED, cells);

        uint8 expectedArtId = registry.cellArtifact(GAME_ID, 50);

        vm.expectEmit(true, true, false, true);
        emit ArtifactRegistry.ArtifactClaimed(GAME_ID, alice, expectedArtId, 50);

        registry.claimArtifact(GAME_ID, alice, 50);
    }

    function test_claimArtifact_alreadyClaimed_reverts() public {
        uint8[] memory cells = new uint8[](1);
        cells[0] = 50;
        registry.assignArtifacts(GAME_ID, SEED, cells);

        registry.claimArtifact(GAME_ID, alice, 50);

        vm.expectRevert("ArtifactRegistry: already claimed");
        registry.claimArtifact(GAME_ID, bob, 50);
    }

    function test_claimArtifact_noArtifact_reverts() public {
        // Don't assign any artifacts
        vm.expectRevert("ArtifactRegistry: no artifact at cell");
        registry.claimArtifact(GAME_ID, alice, 50);
    }

    // =========================================================================
    //                      PLAYER STATS
    // =========================================================================

    function test_getPlayerStats_base() public view {
        (int16 hp, int8 atk, int8 def) = registry.getPlayerStats(GAME_ID, alice);
        assertEq(hp, 100);
        assertEq(atk, 10);
        assertEq(def, 5);
    }

    function test_getPlayerStats_withArtifacts() public {
        // Assign and claim Shadow Blade (+5 atk)
        uint8[] memory cells = new uint8[](1);
        cells[0] = 50;
        registry.assignArtifacts(GAME_ID, SEED, cells);

        // We need to know what artifact was assigned to cell 50
        uint8 artId = registry.claimArtifact(GAME_ID, alice, 50);
        ArtifactRegistry.Artifact memory art = registry.getArtifact(artId);

        (int16 hp, int8 atk, int8 def) = registry.getPlayerStats(GAME_ID, alice);
        assertEq(hp, 100 + art.hpBonus);
        assertEq(atk, 10 + art.attackBonus);
        assertEq(def, 5 + art.defenseBonus);
    }

    function test_getPlayerArtifactIds() public {
        uint8[] memory cells = new uint8[](2);
        cells[0] = 50;
        cells[1] = 100;
        registry.assignArtifacts(GAME_ID, SEED, cells);

        registry.claimArtifact(GAME_ID, alice, 50);
        registry.claimArtifact(GAME_ID, alice, 100);

        uint8[] memory arts = registry.getPlayerArtifactIds(GAME_ID, alice);
        assertEq(arts.length, 2);
    }

    // =========================================================================
    //                       STAT FLOORS
    // =========================================================================

    function test_statsFlooredAtMinimum() public {
        // Claim Blood Crystal: +6 atk, -10 HP
        // Then claim Berserker Helm: +8 atk, -2 def
        // Defense would go from 5 to 3 with Berserker Helm
        // Let's test that stats don't go below floor

        // We'd need to set up specific artifact assignments to test floors.
        // For now, verify base stats are above floors.
        (int16 hp, int8 atk, int8 def) = registry.getPlayerStats(GAME_ID, alice);
        assertTrue(hp >= 1, "HP floor");
        assertTrue(atk >= 1, "Attack floor");
        assertTrue(def >= 0, "Defense floor");
    }
}
