use std::hash::pedersen_hash;

/// Maximum number of artifacts a player can hold
global MAX_ARTIFACTS: u32 = 8;

/// Base stats for all players
global BASE_HP: u32 = 100;
global BASE_ATTACK: u32 = 10;
global BASE_DEFENSE: u32 = 5;

/// Grid size for bounds checking
global GRID_SIZE: u8 = 16;

/// Artifact stat bonuses as lookup tables (indexed by artifact_id 0-8)
/// Format: [hp_bonus, atk_bonus, def_bonus, hp_penalty, atk_penalty, def_penalty]
///
/// Matches ArtifactRegistry.sol definitions:
///   ID 0: Empty slot      -> all zeros
///   ID 1: Shadow Blade    -> ATK +5
///   ID 2: Iron Aegis      -> DEF +5
///   ID 3: Vitality Amulet -> HP +20
///   ID 4: Berserker Helm  -> ATK +8, DEF -2
///   ID 5: Phantom Cloak   -> ATK -1, DEF +7, HP +10
///   ID 6: War Gauntlets   -> ATK +3, DEF +3
///   ID 7: Blood Crystal   -> ATK +6, HP -10
///   ID 8: Soul Vessel     -> ATK +2, DEF +2, HP +15

// HP bonuses by artifact ID (0-8)
global HP_BONUS: [u32; 9] = [0, 0, 0, 20, 0, 10, 0, 0, 15];
// ATK bonuses by artifact ID
global ATK_BONUS: [u32; 9] = [0, 5, 0, 0, 8, 0, 3, 6, 2];
// DEF bonuses by artifact ID
global DEF_BONUS: [u32; 9] = [0, 0, 5, 0, 0, 7, 3, 0, 2];
// HP penalties by artifact ID
global HP_PENALTY: [u32; 9] = [0, 0, 0, 0, 0, 0, 0, 10, 0];
// ATK penalties by artifact ID
global ATK_PENALTY: [u32; 9] = [0, 0, 0, 0, 0, 1, 0, 0, 0];
// DEF penalties by artifact ID
global DEF_PENALTY: [u32; 9] = [0, 0, 0, 0, 2, 0, 0, 0, 0];

/// Combat Reveal Circuit (SECURED with ownership verification + uniqueness)
/// Proves player stats (HP, attack, defense) are correctly derived from
/// base stats + collected artifacts.
///
/// SECURITY FEATURES:
///   - Position bounds checking (x, y in 0-15)
///   - Artifact ownership verification via inventory commitment
///   - Artifact uniqueness check (no duplicates in claimed set)
///
/// Private inputs: x, y, salt, player_salt, artifact_ids[8], owned_artifacts[8], inventory_salt
/// Public inputs: commitment, stats_commitment, game_id, inventory_commitment
///
/// Proves:
///   1. commitment = hash(x, y, salt)
///   2. Position is within bounds (0-15)
///   3. inventory_commitment matches hash of owned_artifacts + inventory_salt
///   4. All claimed artifact_ids are either 0 (empty) or exist in owned_artifacts
///   5. No duplicate non-zero artifact_ids in the claimed set
///   6. Stats are correctly computed from base + artifact bonuses - penalties
///   7. stats_commitment = hash(hp, attack, defense, player_salt)
///   8. Stats are floored: HP >= 1, ATK >= 1, DEF >= 0
fn main(
    // Private inputs
    x: Field,
    y: Field,
    salt: Field,
    player_salt: Field,
    artifact_ids: [u32; MAX_ARTIFACTS],      // Artifacts claimed for THIS combat
    owned_artifacts: [u32; MAX_ARTIFACTS],   // NEW: Player's full inventory
    inventory_salt: Field,                    // NEW: Salt for inventory commitment
    // Public inputs
    commitment: pub Field,
    stats_commitment: pub Field,
    game_id: pub Field,
    inventory_commitment: pub Field,          // NEW: Commitment to player's inventory
) {
    // 1. Verify position commitment
    let computed_commitment = pedersen_hash([x, y, salt]);
    assert(computed_commitment == commitment, "Position commitment mismatch");

    // 2. NEW: Position bounds check (defense-in-depth)
    let x_u8 = x as u8;
    let y_u8 = y as u8;
    assert(x_u8 < GRID_SIZE, "X coordinate out of bounds");
    assert(y_u8 < GRID_SIZE, "Y coordinate out of bounds");

    // 3. NEW: Verify inventory commitment
    //    This proves the player actually owns the artifacts they're claiming
    let computed_inventory = pedersen_hash([
        owned_artifacts[0] as Field,
        owned_artifacts[1] as Field,
        owned_artifacts[2] as Field,
        owned_artifacts[3] as Field,
        owned_artifacts[4] as Field,
        owned_artifacts[5] as Field,
        owned_artifacts[6] as Field,
        owned_artifacts[7] as Field,
        inventory_salt,
    ]);
    assert(computed_inventory == inventory_commitment, "Inventory commitment mismatch");

    // 4. NEW: Verify each claimed artifact exists in owned_artifacts
    //    Empty slots (0) are always allowed
    for i in 0..MAX_ARTIFACTS {
        let claimed = artifact_ids[i];
        if claimed != 0 {
            // Must find this artifact in owned_artifacts
            let mut found = false;
            for j in 0..MAX_ARTIFACTS {
                if owned_artifacts[j] == claimed {
                    found = true;
                }
            }
            assert(found, "Claimed artifact not in inventory");
        }
    }

    // 5. NEW: Verify no duplicate non-zero artifact_ids
    //    This prevents stacking the same artifact multiple times
    for i in 0..MAX_ARTIFACTS {
        for j in (i + 1)..MAX_ARTIFACTS {
            let aid_i = artifact_ids[i];
            let aid_j = artifact_ids[j];
            // If both are non-zero, they must be different
            if (aid_i != 0) & (aid_j != 0) {
                assert(aid_i != aid_j, "Duplicate artifact in claimed set");
            }
        }
    }

    // 6. Compute stats from base + artifacts using lookup tables
    let mut hp_bonus: u32 = 0;
    let mut atk_bonus: u32 = 0;
    let mut def_bonus: u32 = 0;
    let mut hp_penalty: u32 = 0;
    let mut atk_penalty: u32 = 0;
    let mut def_penalty: u32 = 0;

    for i in 0..MAX_ARTIFACTS {
        let aid = artifact_ids[i];
        // Artifact IDs must be valid (0-8)
        assert(aid <= 8, "Invalid artifact ID");

        // Use lookup tables instead of if-else chain
        hp_bonus += HP_BONUS[aid];
        atk_bonus += ATK_BONUS[aid];
        def_bonus += DEF_BONUS[aid];
        hp_penalty += HP_PENALTY[aid];
        atk_penalty += ATK_PENALTY[aid];
        def_penalty += DEF_PENALTY[aid];
    }

    // Apply bonuses then penalties with floor values matching the contract:
    //   HP >= 1, ATK >= 1, DEF >= 0
    let raw_hp = BASE_HP + hp_bonus;
    let hp = if raw_hp > hp_penalty {
        let result = raw_hp - hp_penalty;
        if result < 1 { 1 } else { result }
    } else {
        1
    };

    let raw_attack = BASE_ATTACK + atk_bonus;
    let attack = if raw_attack > atk_penalty {
        let result = raw_attack - atk_penalty;
        if result < 1 { 1 } else { result }
    } else {
        1
    };

    let raw_defense = BASE_DEFENSE + def_bonus;
    let defense = if raw_defense >= def_penalty {
        raw_defense - def_penalty
    } else {
        0
    };

    // 7. Verify stats commitment
    let computed_stats = pedersen_hash([
        hp as Field,
        attack as Field,
        defense as Field,
        player_salt,
    ]);
    assert(computed_stats == stats_commitment, "Stats commitment mismatch");

    // game_id is included as a public input to bind the proof to a specific game.
    // Prevent replay across games.
    assert(game_id != 0, "Invalid game ID");
}

/// Helper: compute position commitment
fn compute_commitment(x: Field, y: Field, salt: Field) -> Field {
    pedersen_hash([x, y, salt])
}

/// Helper: compute stats commitment
fn compute_stats_commitment(hp: u32, attack: u32, defense: u32, player_salt: Field) -> Field {
    pedersen_hash([hp as Field, attack as Field, defense as Field, player_salt])
}

/// Helper: compute inventory commitment
fn compute_inventory_commitment(owned: [u32; MAX_ARTIFACTS], salt: Field) -> Field {
    pedersen_hash([
        owned[0] as Field,
        owned[1] as Field,
        owned[2] as Field,
        owned[3] as Field,
        owned[4] as Field,
        owned[5] as Field,
        owned[6] as Field,
        owned[7] as Field,
        salt,
    ])
}

// =========================================================================
//                              TESTS
// =========================================================================

#[test]
fn test_no_artifacts() {
    let x: Field = 5;
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 999;
    let inventory_salt: Field = 555;
    let game_id: Field = 1;
    let artifacts: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];
    let owned: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 10, 5, player_salt);
    let inventory_commitment = compute_inventory_commitment(owned, inventory_salt);

    main(x, y, salt, player_salt, artifacts, owned, inventory_salt, commitment, stats_commitment, game_id, inventory_commitment);
}

#[test]
fn test_one_artifact_shadow_blade() {
    // Shadow Blade (ID 1): +5 ATK -> HP=100, ATK=15, DEF=5
    let x: Field = 3;
    let y: Field = 7;
    let salt: Field = 222;
    let player_salt: Field = 888;
    let inventory_salt: Field = 444;
    let game_id: Field = 42;
    
    // Player owns and claims shadow blade
    let artifacts: [u32; MAX_ARTIFACTS] = [1, 0, 0, 0, 0, 0, 0, 0];
    let owned: [u32; MAX_ARTIFACTS] = [1, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 15, 5, player_salt);
    let inventory_commitment = compute_inventory_commitment(owned, inventory_salt);

    main(x, y, salt, player_salt, artifacts, owned, inventory_salt, commitment, stats_commitment, game_id, inventory_commitment);
}

#[test]
fn test_claim_subset_of_owned() {
    // Player owns [1, 2, 3] but only claims [1, 3] for combat
    let x: Field = 5;
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 222;
    let inventory_salt: Field = 333;
    let game_id: Field = 1;
    
    let owned: [u32; MAX_ARTIFACTS] = [1, 2, 3, 0, 0, 0, 0, 0];
    let claimed: [u32; MAX_ARTIFACTS] = [1, 3, 0, 0, 0, 0, 0, 0];
    
    // Stats with just [1, 3]: Shadow Blade + Vitality Amulet
    // HP: 100 + 0 + 20 = 120, ATK: 10 + 5 + 0 = 15, DEF: 5 + 0 + 0 = 5
    
    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(120, 15, 5, player_salt);
    let inventory_commitment = compute_inventory_commitment(owned, inventory_salt);
    
    main(x, y, salt, player_salt, claimed, owned, inventory_salt, commitment, stats_commitment, game_id, inventory_commitment);
}

#[test]
fn test_all_eight_artifacts() {
    // All artifacts: IDs 1-8
    // HP: 100 + 45 - 10 = 135, ATK: 10 + 24 - 1 = 33, DEF: 5 + 17 - 2 = 20
    let x: Field = 0;
    let y: Field = 0;
    let salt: Field = 999;
    let player_salt: Field = 111;
    let inventory_salt: Field = 777;
    let game_id: Field = 99;
    
    let artifacts: [u32; MAX_ARTIFACTS] = [1, 2, 3, 4, 5, 6, 7, 8];
    let owned: [u32; MAX_ARTIFACTS] = [1, 2, 3, 4, 5, 6, 7, 8];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(135, 33, 20, player_salt);
    let inventory_commitment = compute_inventory_commitment(owned, inventory_salt);

    main(x, y, salt, player_salt, artifacts, owned, inventory_salt, commitment, stats_commitment, game_id, inventory_commitment);
}

#[test(should_fail_with = "Claimed artifact not in inventory")]
fn test_fake_artifact_fails() {
    // Player owns nothing but claims Shadow Blade
    let x: Field = 5;
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 999;
    let inventory_salt: Field = 555;
    let game_id: Field = 1;
    
    let owned: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];
    let claimed: [u32; MAX_ARTIFACTS] = [1, 0, 0, 0, 0, 0, 0, 0]; // Fake!

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 15, 5, player_salt);
    let inventory_commitment = compute_inventory_commitment(owned, inventory_salt);

    main(x, y, salt, player_salt, claimed, owned, inventory_salt, commitment, stats_commitment, game_id, inventory_commitment);
}

#[test(should_fail_with = "Claimed artifact not in inventory")]
fn test_artifact_not_owned_fails() {
    // Player owns [1, 2] but claims [1, 2, 3] - doesn't own 3
    let x: Field = 5;
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 222;
    let inventory_salt: Field = 333;
    let game_id: Field = 1;
    
    let owned: [u32; MAX_ARTIFACTS] = [1, 2, 0, 0, 0, 0, 0, 0];
    let claimed: [u32; MAX_ARTIFACTS] = [1, 2, 3, 0, 0, 0, 0, 0]; // 3 not owned!

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(120, 15, 5, player_salt);
    let inventory_commitment = compute_inventory_commitment(owned, inventory_salt);

    main(x, y, salt, player_salt, claimed, owned, inventory_salt, commitment, stats_commitment, game_id, inventory_commitment);
}

#[test(should_fail_with = "Duplicate artifact in claimed set")]
fn test_duplicate_artifacts_fails() {
    // Player owns [1, 2] but tries to claim [1, 1] - duplicate!
    let x: Field = 0;
    let y: Field = 0;
    let salt: Field = 444;
    let player_salt: Field = 666;
    let inventory_salt: Field = 888;
    let game_id: Field = 3;
    
    let owned: [u32; MAX_ARTIFACTS] = [1, 2, 0, 0, 0, 0, 0, 0];
    let claimed: [u32; MAX_ARTIFACTS] = [1, 1, 0, 0, 0, 0, 0, 0]; // Duplicate!

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 20, 5, player_salt); // Would be wrong anyway
    let inventory_commitment = compute_inventory_commitment(owned, inventory_salt);

    main(x, y, salt, player_salt, claimed, owned, inventory_salt, commitment, stats_commitment, game_id, inventory_commitment);
}

#[test(should_fail_with = "X coordinate out of bounds")]
fn test_x_out_of_bounds_fails() {
    let x: Field = 16; // Out of bounds!
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 999;
    let inventory_salt: Field = 555;
    let game_id: Field = 1;
    
    let artifacts: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];
    let owned: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 10, 5, player_salt);
    let inventory_commitment = compute_inventory_commitment(owned, inventory_salt);

    main(x, y, salt, player_salt, artifacts, owned, inventory_salt, commitment, stats_commitment, game_id, inventory_commitment);
}

#[test(should_fail_with = "Y coordinate out of bounds")]
fn test_y_out_of_bounds_fails() {
    let x: Field = 5;
    let y: Field = 20; // Out of bounds!
    let salt: Field = 111;
    let player_salt: Field = 999;
    let inventory_salt: Field = 555;
    let game_id: Field = 1;
    
    let artifacts: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];
    let owned: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 10, 5, player_salt);
    let inventory_commitment = compute_inventory_commitment(owned, inventory_salt);

    main(x, y, salt, player_salt, artifacts, owned, inventory_salt, commitment, stats_commitment, game_id, inventory_commitment);
}

#[test(should_fail_with = "Inventory commitment mismatch")]
fn test_fake_inventory_commitment_fails() {
    // Player tries to fake their inventory
    let x: Field = 5;
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 999;
    let inventory_salt: Field = 555;
    let game_id: Field = 1;
    
    // Real inventory (empty) and claimed (empty)
    let artifacts: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];
    let real_owned: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];
    
    // But provide fake inventory commitment claiming ownership of [1,2,3,4,5,6,7,8]
    let fake_owned: [u32; MAX_ARTIFACTS] = [1, 2, 3, 4, 5, 6, 7, 8];
    let fake_inventory_commitment = compute_inventory_commitment(fake_owned, inventory_salt);

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 10, 5, player_salt);

    // Circuit will verify owned_artifacts matches inventory_commitment - should fail
    main(x, y, salt, player_salt, artifacts, real_owned, inventory_salt, commitment, stats_commitment, game_id, fake_inventory_commitment);
}

#[test(should_fail_with = "Stats commitment mismatch")]
fn test_wrong_stats_fails() {
    let x: Field = 5;
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 999;
    let inventory_salt: Field = 555;
    let game_id: Field = 1;
    
    // Has Shadow Blade (+5 ATK) but claims base stats
    let artifacts: [u32; MAX_ARTIFACTS] = [1, 0, 0, 0, 0, 0, 0, 0];
    let owned: [u32; MAX_ARTIFACTS] = [1, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let wrong_stats = compute_stats_commitment(100, 10, 5, player_salt); // Should be ATK=15
    let inventory_commitment = compute_inventory_commitment(owned, inventory_salt);

    main(x, y, salt, player_salt, artifacts, owned, inventory_salt, commitment, wrong_stats, game_id, inventory_commitment);
}

#[test(should_fail_with = "Position commitment mismatch")]
fn test_wrong_position_fails() {
    let player_salt: Field = 999;
    let inventory_salt: Field = 555;
    let game_id: Field = 1;
    
    let artifacts: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];
    let owned: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];

    let stats_commitment = compute_stats_commitment(100, 10, 5, player_salt);
    let inventory_commitment = compute_inventory_commitment(owned, inventory_salt);

    main(5, 5, 111, player_salt, artifacts, owned, inventory_salt, 0, stats_commitment, game_id, inventory_commitment);
}

#[test(should_fail_with = "Invalid game ID")]
fn test_zero_game_id_fails() {
    let x: Field = 5;
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 999;
    let inventory_salt: Field = 555;
    
    let artifacts: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];
    let owned: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 10, 5, player_salt);
    let inventory_commitment = compute_inventory_commitment(owned, inventory_salt);

    main(x, y, salt, player_salt, artifacts, owned, inventory_salt, commitment, stats_commitment, 0, inventory_commitment);
}

#[test(should_fail_with = "Invalid artifact ID")]
fn test_invalid_artifact_id_fails() {
    let x: Field = 5;
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 999;
    let inventory_salt: Field = 555;
    let game_id: Field = 1;
    
    // Invalid artifact ID 99
    let artifacts: [u32; MAX_ARTIFACTS] = [99, 0, 0, 0, 0, 0, 0, 0];
    let owned: [u32; MAX_ARTIFACTS] = [99, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 10, 5, player_salt);
    let inventory_commitment = compute_inventory_commitment(owned, inventory_salt);

    main(x, y, salt, player_salt, artifacts, owned, inventory_salt, commitment, stats_commitment, game_id, inventory_commitment);
}
