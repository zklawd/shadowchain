use std::hash::pedersen_hash;

/// Maximum number of artifacts a player can hold
global MAX_ARTIFACTS: u32 = 8;

/// Base stats for all players
global BASE_HP: u32 = 100;
global BASE_ATTACK: u32 = 10;
global BASE_DEFENSE: u32 = 5;

/// Artifact stat bonuses and penalties (indexed by artifact_id 1..8)
/// artifact_id 0 = no artifact (empty slot)
///
/// Returns [hp_bonus, atk_bonus, def_bonus, hp_penalty, atk_penalty, def_penalty]
/// Positive and negative modifiers are tracked separately since circuits use u32.
///
/// Matches ArtifactRegistry.sol definitions:
///   ID 1: Shadow Blade    -> ATK +5,  DEF  0, HP   0
///   ID 2: Iron Aegis      -> ATK  0,  DEF +5, HP   0
///   ID 3: Vitality Amulet -> ATK  0,  DEF  0, HP +20
///   ID 4: Berserker Helm  -> ATK +8,  DEF -2, HP   0
///   ID 5: Phantom Cloak   -> ATK -1,  DEF +7, HP +10
///   ID 6: War Gauntlets   -> ATK +3,  DEF +3, HP   0
///   ID 7: Blood Crystal   -> ATK +6,  DEF  0, HP -10
///   ID 8: Soul Vessel     -> ATK +2,  DEF +2, HP +15
fn get_artifact_bonus(artifact_id: u32) -> [u32; 6] {
    if artifact_id == 1 {
        // Shadow Blade: +5 ATK
        [0, 5, 0, 0, 0, 0]
    } else if artifact_id == 2 {
        // Iron Aegis: +5 DEF
        [0, 0, 5, 0, 0, 0]
    } else if artifact_id == 3 {
        // Vitality Amulet: +20 HP
        [20, 0, 0, 0, 0, 0]
    } else if artifact_id == 4 {
        // Berserker Helm: +8 ATK, -2 DEF
        [0, 8, 0, 0, 0, 2]
    } else if artifact_id == 5 {
        // Phantom Cloak: -1 ATK, +7 DEF, +10 HP
        [10, 0, 7, 0, 1, 0]
    } else if artifact_id == 6 {
        // War Gauntlets: +3 ATK, +3 DEF
        [0, 3, 3, 0, 0, 0]
    } else if artifact_id == 7 {
        // Blood Crystal: +6 ATK, -10 HP
        [0, 6, 0, 10, 0, 0]
    } else if artifact_id == 8 {
        // Soul Vessel: +2 ATK, +2 DEF, +15 HP
        [15, 2, 2, 0, 0, 0]
    } else {
        // artifact_id == 0 means empty slot, no bonus
        [0, 0, 0, 0, 0, 0]
    }
}

/// Combat Reveal Circuit
/// Proves player stats (HP, attack, defense) are correctly derived from
/// base stats + collected artifacts.
///
/// Private inputs: x, y, salt, player_salt, artifact_ids[8]
/// Public inputs: commitment, stats_commitment, game_id
///
/// Proves:
///   1. commitment = hash(x, y, salt)
///   2. Stats are correctly computed from base + artifact bonuses - penalties
///   3. stats_commitment = hash(hp, attack, defense, player_salt)
///   4. Stats are floored: HP >= 1, ATK >= 1, DEF >= 0 (matching contract)
fn main(
    // Private inputs
    x: Field,
    y: Field,
    salt: Field,
    player_salt: Field,
    artifact_ids: [u32; MAX_ARTIFACTS],
    // Public inputs
    commitment: pub Field,
    stats_commitment: pub Field,
    game_id: pub Field,
) {
    // 1. Verify position commitment
    let computed_commitment = pedersen_hash([x, y, salt]);
    assert(computed_commitment == commitment, "Position commitment mismatch");

    // 2. Compute stats from base + artifacts
    //    Track bonuses and penalties separately to avoid u32 underflow
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

        let mods = get_artifact_bonus(aid);
        hp_bonus += mods[0];
        atk_bonus += mods[1];
        def_bonus += mods[2];
        hp_penalty += mods[3];
        atk_penalty += mods[4];
        def_penalty += mods[5];
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

    // 3. Verify stats commitment
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

// =========================================================================
//                              TESTS
// =========================================================================

#[test]
fn test_no_artifacts() {
    let x: Field = 5;
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 999;
    let game_id: Field = 1;
    let artifacts: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 10, 5, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, game_id);
}

#[test]
fn test_one_artifact_shadow_blade() {
    // Shadow Blade (ID 1): +5 ATK -> HP=100, ATK=15, DEF=5
    let x: Field = 3;
    let y: Field = 7;
    let salt: Field = 222;
    let player_salt: Field = 888;
    let game_id: Field = 42;
    let artifacts: [u32; MAX_ARTIFACTS] = [1, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 15, 5, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, game_id);
}

#[test]
fn test_vitality_amulet() {
    // Vitality Amulet (ID 3): +20 HP -> HP=120, ATK=10, DEF=5
    let x: Field = 1;
    let y: Field = 1;
    let salt: Field = 500;
    let player_salt: Field = 600;
    let game_id: Field = 10;
    let artifacts: [u32; MAX_ARTIFACTS] = [3, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(120, 10, 5, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, game_id);
}

#[test]
fn test_berserker_helm_negative_defense() {
    // Berserker Helm (ID 4): +8 ATK, -2 DEF -> HP=100, ATK=18, DEF=3
    let x: Field = 8;
    let y: Field = 2;
    let salt: Field = 300;
    let player_salt: Field = 400;
    let game_id: Field = 5;
    let artifacts: [u32; MAX_ARTIFACTS] = [4, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 18, 3, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, game_id);
}

#[test]
fn test_blood_crystal_negative_hp() {
    // Blood Crystal (ID 7): +6 ATK, -10 HP -> HP=90, ATK=16, DEF=5
    let x: Field = 12;
    let y: Field = 4;
    let salt: Field = 700;
    let player_salt: Field = 800;
    let game_id: Field = 15;
    let artifacts: [u32; MAX_ARTIFACTS] = [7, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(90, 16, 5, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, game_id);
}

#[test]
fn test_phantom_cloak_negative_attack() {
    // Phantom Cloak (ID 5): -1 ATK, +7 DEF, +10 HP -> HP=110, ATK=9, DEF=12
    let x: Field = 6;
    let y: Field = 6;
    let salt: Field = 550;
    let player_salt: Field = 660;
    let game_id: Field = 20;
    let artifacts: [u32; MAX_ARTIFACTS] = [5, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(110, 9, 12, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, game_id);
}

#[test]
fn test_multiple_artifacts_positive_only() {
    // Shadow Blade (1) + Iron Aegis (2) + Vitality Amulet (3) + War Gauntlets (6) + Soul Vessel (8)
    // HP:  100 + 0 + 0 + 20 + 0 + 15 = 135
    // ATK: 10  + 5 + 0 + 0  + 3 + 2  = 20
    // DEF: 5   + 0 + 5 + 0  + 3 + 2  = 15
    let x: Field = 10;
    let y: Field = 2;
    let salt: Field = 333;
    let player_salt: Field = 777;
    let game_id: Field = 7;
    let artifacts: [u32; MAX_ARTIFACTS] = [1, 2, 3, 6, 8, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(135, 20, 15, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, game_id);
}

#[test]
fn test_all_eight_artifacts() {
    // All artifacts: IDs 1-8
    // HP bonuses:  0+0+20+0+10+0+0+15 = 45,  penalties: 0+0+0+0+0+0+10+0 = 10  -> HP = 100+45-10 = 135
    // ATK bonuses: 5+0+0+8+0+3+6+2 = 24,     penalties: 0+0+0+0+1+0+0+0 = 1    -> ATK = 10+24-1 = 33
    // DEF bonuses: 0+5+0+0+7+3+0+2 = 17,     penalties: 0+0+0+2+0+0+0+0 = 2    -> DEF = 5+17-2 = 20
    let x: Field = 0;
    let y: Field = 0;
    let salt: Field = 999;
    let player_salt: Field = 111;
    let game_id: Field = 99;
    let artifacts: [u32; MAX_ARTIFACTS] = [1, 2, 3, 4, 5, 6, 7, 8];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(135, 33, 20, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, game_id);
}

#[test]
fn test_duplicate_artifacts() {
    // Two Shadow Blades: HP=100, ATK=10+5+5=20, DEF=5
    let x: Field = 0;
    let y: Field = 0;
    let salt: Field = 444;
    let player_salt: Field = 666;
    let game_id: Field = 3;
    let artifacts: [u32; MAX_ARTIFACTS] = [1, 1, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 20, 5, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, game_id);
}

#[test(should_fail_with = "Stats commitment mismatch")]
fn test_wrong_stats_fails() {
    let x: Field = 5;
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 999;
    let game_id: Field = 1;
    // Has Shadow Blade (+5 ATK) but claims base stats
    let artifacts: [u32; MAX_ARTIFACTS] = [1, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let wrong_stats = compute_stats_commitment(100, 10, 5, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, wrong_stats, game_id);
}

#[test(should_fail_with = "Position commitment mismatch")]
fn test_wrong_position_fails() {
    let player_salt: Field = 999;
    let game_id: Field = 1;
    let artifacts: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];

    let stats_commitment = compute_stats_commitment(100, 10, 5, player_salt);

    main(5, 5, 111, player_salt, artifacts, 0, stats_commitment, game_id);
}

#[test(should_fail_with = "Invalid game ID")]
fn test_zero_game_id_fails() {
    let x: Field = 5;
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 999;
    let artifacts: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 10, 5, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, 0);
}

#[test(should_fail_with = "Invalid artifact ID")]
fn test_invalid_artifact_id_fails() {
    let x: Field = 5;
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 999;
    let game_id: Field = 1;
    let artifacts: [u32; MAX_ARTIFACTS] = [99, 0, 0, 0, 0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 10, 5, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, game_id);
}
