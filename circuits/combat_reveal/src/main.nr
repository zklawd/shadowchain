use std::hash::pedersen_hash;

/// Maximum number of artifacts a player can hold
global MAX_ARTIFACTS: u32 = 4;

/// Base stats for all players
global BASE_HP: u32 = 100;
global BASE_ATTACK: u32 = 10;
global BASE_DEFENSE: u32 = 5;

/// Artifact stat bonuses (indexed by artifact_id 1..4)
/// artifact_id 0 = no artifact (empty slot)
/// Each artifact: [hp_bonus, attack_bonus, defense_bonus]
///
/// Artifact 1: HP Potion    (+20 HP,  +0 ATK, +0 DEF)
/// Artifact 2: Sharp Blade  (+0  HP,  +5 ATK, +0 DEF)
/// Artifact 3: Iron Shield  (+0  HP,  +0 ATK, +5 DEF)
/// Artifact 4: War Relic    (+10 HP,  +3 ATK, +3 DEF)
fn get_artifact_bonus(artifact_id: u32) -> [u32; 3] {
    if artifact_id == 1 {
        [20, 0, 0]
    } else if artifact_id == 2 {
        [0, 5, 0]
    } else if artifact_id == 3 {
        [0, 0, 5]
    } else if artifact_id == 4 {
        [10, 3, 3]
    } else {
        // artifact_id == 0 means empty slot, no bonus
        [0, 0, 0]
    }
}

/// Combat Reveal Circuit
/// Proves player stats (HP, attack, defense) are correctly derived from
/// base stats + collected artifacts.
///
/// Private inputs: x, y, salt, player_salt, artifact_ids[4]
/// Public inputs: commitment, stats_commitment, game_id
///
/// Proves:
///   1. commitment = hash(x, y, salt)
///   2. Stats are correctly computed from base + artifact bonuses
///   3. stats_commitment = hash(hp, attack, defense, player_salt)
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
    let mut hp = BASE_HP;
    let mut attack = BASE_ATTACK;
    let mut defense = BASE_DEFENSE;

    for i in 0..MAX_ARTIFACTS {
        let aid = artifact_ids[i];
        // Artifact IDs must be valid (0-4)
        assert(aid <= 4, "Invalid artifact ID");

        let bonus = get_artifact_bonus(aid);
        hp += bonus[0];
        attack += bonus[1];
        defense += bonus[2];
    }

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

#[test]
fn test_no_artifacts() {
    let x: Field = 5;
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 999;
    let game_id: Field = 1;
    let artifacts: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 10, 5, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, game_id);
}

#[test]
fn test_one_artifact_hp_potion() {
    let x: Field = 3;
    let y: Field = 7;
    let salt: Field = 222;
    let player_salt: Field = 888;
    let game_id: Field = 42;
    let artifacts: [u32; MAX_ARTIFACTS] = [1, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    // HP=100+20=120, ATK=10, DEF=5
    let stats_commitment = compute_stats_commitment(120, 10, 5, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, game_id);
}

#[test]
fn test_multiple_artifacts() {
    let x: Field = 10;
    let y: Field = 2;
    let salt: Field = 333;
    let player_salt: Field = 777;
    let game_id: Field = 7;
    // HP Potion + Sharp Blade + Iron Shield + War Relic
    let artifacts: [u32; MAX_ARTIFACTS] = [1, 2, 3, 4];

    let commitment = compute_commitment(x, y, salt);
    // HP=130, ATK=18, DEF=13
    let stats_commitment = compute_stats_commitment(130, 18, 13, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, game_id);
}

#[test]
fn test_duplicate_artifacts() {
    let x: Field = 0;
    let y: Field = 0;
    let salt: Field = 444;
    let player_salt: Field = 666;
    let game_id: Field = 3;
    // Two Sharp Blades
    let artifacts: [u32; MAX_ARTIFACTS] = [2, 2, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    // HP=100, ATK=10+5+5=20, DEF=5
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
    let artifacts: [u32; MAX_ARTIFACTS] = [1, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    // Wrong: claiming base stats but has HP Potion
    let wrong_stats = compute_stats_commitment(100, 10, 5, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, wrong_stats, game_id);
}

#[test(should_fail_with = "Position commitment mismatch")]
fn test_wrong_position_fails() {
    let player_salt: Field = 999;
    let game_id: Field = 1;
    let artifacts: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0];

    let stats_commitment = compute_stats_commitment(100, 10, 5, player_salt);

    main(5, 5, 111, player_salt, artifacts, 0, stats_commitment, game_id);
}

#[test(should_fail_with = "Invalid game ID")]
fn test_zero_game_id_fails() {
    let x: Field = 5;
    let y: Field = 5;
    let salt: Field = 111;
    let player_salt: Field = 999;
    let artifacts: [u32; MAX_ARTIFACTS] = [0, 0, 0, 0];

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
    let artifacts: [u32; MAX_ARTIFACTS] = [99, 0, 0, 0];

    let commitment = compute_commitment(x, y, salt);
    let stats_commitment = compute_stats_commitment(100, 10, 5, player_salt);

    main(x, y, salt, player_salt, artifacts, commitment, stats_commitment, game_id);
}
