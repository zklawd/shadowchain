use std::hash::pedersen_hash;
use poseidon::poseidon::bn254::hash_3;
use poseidon::poseidon::bn254::hash_4;
use poseidon::poseidon::bn254::hash_5;

/// Threshold for treasure cells (same as contract: hash % 256 < 20 means ~7.8% of cells)
global TREASURE_THRESHOLD: Field = 20;

/// Domain separator for artifact ID derivation (must match contract!)
/// "artifact" as ASCII: 0x617274696661637400
global ARTIFACT_DOMAIN_SEP: Field = 0x617274696661637400;

/// Domain separator for nullifier derivation
/// "nullifier" as ASCII
global NULLIFIER_DOMAIN_SEP: Field = 0x6e756c6c6966696572;

// ============================================================
// Unconstrained helpers for witness generation
// ============================================================

/// Get the last byte of a field (f mod 256) and the quotient
unconstrained fn decompose_mod_256(f: Field) -> (Field, Field) {
    let bytes = f.to_be_bytes::<32>();
    let last_byte = bytes[31] as Field;
    let quotient = (f - last_byte) / 256;
    (last_byte, quotient)
}

/// Claim Artifact Circuit (SECURED with Nullifier)
/// Proves a player is at a valid procedurally-generated treasure cell.
/// Includes nullifier to prevent double-claiming.
///
/// Private inputs: x, y, salt, player_secret
/// Public inputs: commitment, treasure_seed, artifact_id, nullifier
///
/// Proves:
///   1. commitment = pedersen(x, y, salt)  -- player knows their position
///   2. poseidon(x, y, treasure_seed) % 256 < THRESHOLD -- cell is a treasure
///   3. artifact_id matches poseidon(x, y, treasure_seed, ARTIFACT_DOMAIN_SEP) derivation
///   4. nullifier = poseidon(player_secret, x, y, treasure_seed, NULLIFIER_DOMAIN_SEP) -- unique claim identifier
///
/// SECURITY: The contract MUST track used nullifiers and reject duplicates.
/// Each (player_secret, treasure_location) pair produces a unique nullifier.
fn main(
    // Private inputs
    x: Field,
    y: Field,
    salt: Field,
    player_secret: Field,  // NEW: Player's secret for nullifier derivation
    // Public inputs
    commitment: pub Field,
    treasure_seed: pub Field,
    artifact_id: pub Field,
    nullifier: pub Field,  // NEW: Prevents double-claiming
) {
    // Validate coordinates are in bounds (0-15)
    assert(x as u8 < 16, "X coordinate out of bounds");
    assert(y as u8 < 16, "Y coordinate out of bounds");

    // 1. Verify position commitment (still using Pedersen for commitments)
    let computed_commitment = pedersen_hash([x, y, salt]);
    assert(computed_commitment == commitment, "Position commitment mismatch");

    // 2. Verify cell is a procedural treasure using POSEIDON
    //    poseidon(x, y, treasure_seed) % 256 < THRESHOLD
    let cell_hash = hash_3([x, y, treasure_seed]);
    
    // Safety: decompose_mod_256 computes f mod 256 and quotient, verified below
    let (cell_last_byte, cell_quotient) = unsafe { decompose_mod_256(cell_hash) };
    // Verify decomposition: cell_hash == quotient * 256 + last_byte
    assert(cell_hash == cell_quotient * 256 + cell_last_byte, "Cell hash decomposition failed");
    // Verify last_byte < 256 (range check)
    assert((cell_last_byte as u8) as Field == cell_last_byte, "Cell byte range check failed");
    // Verify it's a treasure
    assert(cell_last_byte as u8 < TREASURE_THRESHOLD as u8, "Cell is not a treasure");

    // 3. Verify artifact_id matches derivation using POSEIDON
    //    artifact_id = (poseidon(x, y, treasure_seed, ARTIFACT_DOMAIN_SEP) % 8) + 1
    let artifact_hash = hash_4([x, y, treasure_seed, ARTIFACT_DOMAIN_SEP]);
    
    // Safety: decompose_mod_256 computes f mod 256, verified below  
    let (artifact_last_byte, artifact_quotient) = unsafe { decompose_mod_256(artifact_hash) };
    // Verify decomposition
    assert(artifact_hash == artifact_quotient * 256 + artifact_last_byte, "Artifact hash decomposition failed");
    // Verify last_byte < 256
    assert((artifact_last_byte as u8) as Field == artifact_last_byte, "Artifact byte range check failed");
    
    // Compute derived_id = (last_byte % 8) + 1
    let derived_remainder = artifact_last_byte as u8 % 8;
    let derived_id = (derived_remainder + 1) as Field;
    assert(artifact_id == derived_id, "Artifact ID mismatch");

    // 4. NEW: Verify nullifier - prevents replay attacks
    //    nullifier = poseidon(player_secret, x, y, treasure_seed, NULLIFIER_DOMAIN_SEP)
    //    This binds the player's identity to this specific treasure location.
    //    The contract MUST track used nullifiers and reject duplicates.
    let computed_nullifier = hash_5([player_secret, x, y, treasure_seed, NULLIFIER_DOMAIN_SEP]);
    assert(computed_nullifier == nullifier, "Nullifier mismatch");
}

/// Helper: compute a position commitment (still uses Pedersen)
fn compute_commitment(x: Field, y: Field, salt: Field) -> Field {
    pedersen_hash([x, y, salt])
}

/// Helper: compute nullifier for a claim
fn compute_nullifier(player_secret: Field, x: Field, y: Field, treasure_seed: Field) -> Field {
    hash_5([player_secret, x, y, treasure_seed, NULLIFIER_DOMAIN_SEP])
}

/// Helper: check if a cell is a treasure using Poseidon
fn is_treasure(x: Field, y: Field, treasure_seed: Field) -> bool {
    let cell_hash = hash_3([x, y, treasure_seed]);
    let cell_hash_bytes = cell_hash.to_be_bytes::<32>();
    let hash_mod = cell_hash_bytes[31] as u32;
    hash_mod < TREASURE_THRESHOLD as u32
}

// ============================================================
// Test helpers (unconstrained for efficiency)
// ============================================================

/// Find a treasure cell for testing using Poseidon
unconstrained fn find_treasure_cell(treasure_seed: Field) -> (Field, Field) {
    let mut result_x: Field = 0;
    let mut result_y: Field = 0;
    let mut found = false;
    
    for y in 0..16 {
        for x in 0..16 {
            if !found {
                let cell_hash = poseidon::poseidon::bn254::hash_3([x as Field, y as Field, treasure_seed]);
                let cell_hash_bytes = cell_hash.to_be_bytes::<32>();
                let hash_mod = cell_hash_bytes[31] as u32;
                if hash_mod < TREASURE_THRESHOLD as u32 {
                    result_x = x as Field;
                    result_y = y as Field;
                    found = true;
                }
            }
        }
    }
    (result_x, result_y)
}

/// Find a non-treasure cell for testing
unconstrained fn find_non_treasure_cell(treasure_seed: Field) -> (Field, Field) {
    let mut result_x: Field = 0;
    let mut result_y: Field = 0;
    let mut found = false;
    
    for y in 0..16 {
        for x in 0..16 {
            if !found {
                let cell_hash = poseidon::poseidon::bn254::hash_3([x as Field, y as Field, treasure_seed]);
                let cell_hash_bytes = cell_hash.to_be_bytes::<32>();
                let hash_mod = cell_hash_bytes[31] as u32;
                if hash_mod >= TREASURE_THRESHOLD as u32 {
                    result_x = x as Field;
                    result_y = y as Field;
                    found = true;
                }
            }
        }
    }
    (result_x, result_y)
}

/// Get artifact ID (unconstrained version)
unconstrained fn get_artifact_id_unconstrained(x: Field, y: Field, treasure_seed: Field) -> u32 {
    let artifact_hash = poseidon::poseidon::bn254::hash_4([x, y, treasure_seed, ARTIFACT_DOMAIN_SEP]);
    let artifact_bytes = artifact_hash.to_be_bytes::<32>();
    ((artifact_bytes[31] as u32) % 8) + 1
}

// ============================================================
// Tests
// ============================================================

#[test]
fn test_valid_claim_with_nullifier() {
    let treasure_seed: Field = 12345;
    let player_secret: Field = 0xdeadbeef;
    
    // Safety: test-only unconstrained helper to find treasure
    let (x, y) = unsafe { find_treasure_cell(treasure_seed) };
    let salt: Field = 42;

    let commitment = compute_commitment(x, y, salt);
    // Safety: test-only unconstrained helper
    let artifact_id = unsafe { get_artifact_id_unconstrained(x, y, treasure_seed) } as Field;
    let nullifier = compute_nullifier(player_secret, x, y, treasure_seed);

    main(x, y, salt, player_secret, commitment, treasure_seed, artifact_id, nullifier);
}

#[test]
fn test_different_players_different_nullifiers() {
    let treasure_seed: Field = 12345;
    let (x, y) = unsafe { find_treasure_cell(treasure_seed) };
    
    let player1_secret: Field = 0x1111;
    let player2_secret: Field = 0x2222;
    
    let nullifier1 = compute_nullifier(player1_secret, x, y, treasure_seed);
    let nullifier2 = compute_nullifier(player2_secret, x, y, treasure_seed);
    
    // Different players get different nullifiers for same treasure
    assert(nullifier1 != nullifier2, "Nullifiers should differ for different players");
}

#[test]
fn test_same_player_different_treasures_different_nullifiers() {
    let player_secret: Field = 0xabcd;
    let seed1: Field = 11111;
    let seed2: Field = 22222;
    
    let (x1, y1) = unsafe { find_treasure_cell(seed1) };
    let (x2, y2) = unsafe { find_treasure_cell(seed2) };
    
    let nullifier1 = compute_nullifier(player_secret, x1, y1, seed1);
    let nullifier2 = compute_nullifier(player_secret, x2, y2, seed2);
    
    // Same player, different treasures = different nullifiers
    assert(nullifier1 != nullifier2, "Nullifiers should differ for different treasures");
}

#[test(should_fail_with = "Nullifier mismatch")]
fn test_wrong_nullifier_fails() {
    let treasure_seed: Field = 12345;
    let player_secret: Field = 0xdeadbeef;
    
    let (x, y) = unsafe { find_treasure_cell(treasure_seed) };
    let salt: Field = 42;

    let commitment = compute_commitment(x, y, salt);
    let artifact_id = unsafe { get_artifact_id_unconstrained(x, y, treasure_seed) } as Field;
    
    // Wrong nullifier - should fail
    let wrong_nullifier: Field = 0x12345;
    main(x, y, salt, player_secret, commitment, treasure_seed, artifact_id, wrong_nullifier);
}

#[test(should_fail_with = "Nullifier mismatch")]
fn test_replay_with_different_secret_fails() {
    let treasure_seed: Field = 12345;
    let real_player_secret: Field = 0xdeadbeef;
    let attacker_secret: Field = 0xbaddad;
    
    let (x, y) = unsafe { find_treasure_cell(treasure_seed) };
    let salt: Field = 42;

    let commitment = compute_commitment(x, y, salt);
    let artifact_id = unsafe { get_artifact_id_unconstrained(x, y, treasure_seed) } as Field;
    
    // Real player's nullifier (which would be marked as used in contract)
    let real_nullifier = compute_nullifier(real_player_secret, x, y, treasure_seed);
    
    // Attacker tries to use same nullifier with different secret - FAILS
    main(x, y, salt, attacker_secret, commitment, treasure_seed, artifact_id, real_nullifier);
}

#[test]
fn test_different_seeds_different_treasures() {
    let seed1: Field = 11111;
    let seed2: Field = 22222;
    
    // Safety: test-only unconstrained helpers
    let (x1, y1) = unsafe { find_treasure_cell(seed1) };
    let (x2, y2) = unsafe { find_treasure_cell(seed2) };
    
    // Just verify both are valid treasures
    assert(is_treasure(x1, y1, seed1));
    assert(is_treasure(x2, y2, seed2));
}

#[test(should_fail_with = "Cell is not a treasure")]
fn test_non_treasure_cell_fails() {
    let treasure_seed: Field = 12345;
    let salt: Field = 42;
    let player_secret: Field = 0x1234;
    
    let (x, y) = unsafe { find_non_treasure_cell(treasure_seed) };

    let commitment = compute_commitment(x, y, salt);
    let nullifier = compute_nullifier(player_secret, x, y, treasure_seed);
    
    // Try to claim artifact 1 at non-treasure cell
    main(x, y, salt, player_secret, commitment, treasure_seed, 1, nullifier);
}

#[test(should_fail_with = "Position commitment mismatch")]
fn test_wrong_commitment_fails() {
    let treasure_seed: Field = 12345;
    let player_secret: Field = 0x5678;
    let (x, y) = unsafe { find_treasure_cell(treasure_seed) };
    let salt: Field = 42;
    let artifact_id = unsafe { get_artifact_id_unconstrained(x, y, treasure_seed) } as Field;
    let nullifier = compute_nullifier(player_secret, x, y, treasure_seed);

    // Wrong commitment - should fail
    main(x, y, salt, player_secret, 0, treasure_seed, artifact_id, nullifier);
}

#[test(should_fail_with = "Artifact ID mismatch")]
fn test_wrong_artifact_id_fails() {
    let treasure_seed: Field = 12345;
    let player_secret: Field = 0x9abc;
    let (x, y) = unsafe { find_treasure_cell(treasure_seed) };
    let salt: Field = 42;

    let commitment = compute_commitment(x, y, salt);
    let nullifier = compute_nullifier(player_secret, x, y, treasure_seed);
    let correct_id = unsafe { get_artifact_id_unconstrained(x, y, treasure_seed) };
    // Pick wrong ID
    let wrong_id = if correct_id == 1 { 2 } else { 1 };

    main(x, y, salt, player_secret, commitment, treasure_seed, wrong_id as Field, nullifier);
}

#[test(should_fail_with = "X coordinate out of bounds")]
fn test_x_out_of_bounds_fails() {
    let treasure_seed: Field = 12345;
    let salt: Field = 42;
    let player_secret: Field = 0xdef0;
    let x: Field = 16; // Out of bounds
    let y: Field = 5;

    let commitment = compute_commitment(x, y, salt);
    let nullifier = compute_nullifier(player_secret, x, y, treasure_seed);
    main(x, y, salt, player_secret, commitment, treasure_seed, 1, nullifier);
}

#[test(should_fail_with = "Y coordinate out of bounds")]
fn test_y_out_of_bounds_fails() {
    let treasure_seed: Field = 12345;
    let salt: Field = 42;
    let player_secret: Field = 0x1234;
    let x: Field = 5;
    let y: Field = 20; // Out of bounds

    let commitment = compute_commitment(x, y, salt);
    let nullifier = compute_nullifier(player_secret, x, y, treasure_seed);
    main(x, y, salt, player_secret, commitment, treasure_seed, 1, nullifier);
}

/// Cross-check test: verify hashes match what Solidity produces
#[test]
fn test_cross_check_with_solidity() {
    let x: Field = 5;
    let y: Field = 10;
    let seed: Field = 12345;
    
    let cell_hash = hash_3([x, y, seed]);
    
    // This MUST match what Solidity's PoseidonT4.hash([5, 10, 12345]) returns
    let expected_cell_hash: Field = 0x18f86d5a25285414dde90acbf12c8878ccb98ac255c572800aec7c97745855c0;
    assert(cell_hash == expected_cell_hash, "CRITICAL: Cell hash mismatch with Solidity!");
}
