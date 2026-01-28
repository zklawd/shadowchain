use std::hash::pedersen_hash;

/// Threshold for treasure cells (same as contract: hash % 256 < 20 means ~7.8% of cells)
global TREASURE_THRESHOLD: u32 = 20;

/// Claim Artifact Circuit (Procedural Treasures)
/// Proves a player is at a valid procedurally-generated treasure cell.
///
/// Private inputs: x, y, salt
/// Public inputs: commitment, treasure_seed, artifact_id
///
/// Proves:
///   1. commitment = hash(x, y, salt)  -- player knows their position
///   2. hash(x, y, treasure_seed) % 256 < THRESHOLD -- cell is a treasure
///   3. artifact_id matches derivation from (x, y, treasure_seed)
fn main(
    // Private inputs
    x: Field,
    y: Field,
    salt: Field,
    // Public inputs
    commitment: pub Field,
    treasure_seed: pub Field,
    artifact_id: pub Field,
) {
    // Validate coordinates are in bounds (0-15)
    let x_u8 = x as u8;
    let y_u8 = y as u8;
    assert(x_u8 < 16, "X coordinate out of bounds");
    assert(y_u8 < 16, "Y coordinate out of bounds");

    // 1. Verify position commitment
    let computed_commitment = pedersen_hash([x, y, salt]);
    assert(computed_commitment == commitment, "Position commitment mismatch");

    // 2. Verify cell is a procedural treasure
    //    hash(x, y, treasure_seed) % 256 < THRESHOLD
    let cell_hash = pedersen_hash([x, y, treasure_seed]);
    let cell_hash_bytes = cell_hash.to_be_bytes::<32>();
    // Use last byte for modulo 256
    let hash_mod = cell_hash_bytes[31] as u32;
    assert(hash_mod < TREASURE_THRESHOLD, "Cell is not a treasure");

    // 3. Verify artifact_id matches derivation
    //    artifact_id = (hash(x, y, treasure_seed, "artifact") % 8) + 1
    let artifact_hash = pedersen_hash([x, y, treasure_seed, 0x617274696661637400]); // "artifact\0" as field
    let artifact_bytes = artifact_hash.to_be_bytes::<32>();
    let derived_id = ((artifact_bytes[31] as u32) % 8) + 1;
    assert(artifact_id as u32 == derived_id, "Artifact ID mismatch");

    // Validate artifact_id is in valid range
    let aid = artifact_id as u32;
    assert(aid >= 1, "Invalid artifact ID");
    assert(aid <= 8, "Artifact ID out of range");
}

/// Helper: compute a position commitment
fn compute_commitment(x: Field, y: Field, salt: Field) -> Field {
    pedersen_hash([x, y, salt])
}

/// Helper: check if a cell is a treasure
fn is_treasure(x: Field, y: Field, treasure_seed: Field) -> bool {
    let cell_hash = pedersen_hash([x, y, treasure_seed]);
    let cell_hash_bytes = cell_hash.to_be_bytes::<32>();
    let hash_mod = cell_hash_bytes[31] as u32;
    hash_mod < TREASURE_THRESHOLD
}

/// Helper: compute artifact ID at a treasure cell
fn get_artifact_id(x: Field, y: Field, treasure_seed: Field) -> u32 {
    let artifact_hash = pedersen_hash([x, y, treasure_seed, 0x617274696661637400]);
    let artifact_bytes = artifact_hash.to_be_bytes::<32>();
    ((artifact_bytes[31] as u32) % 8) + 1
}

// ============================================================
// Test helpers (unconstrained for efficiency)
// ============================================================

/// Find a treasure cell for testing
unconstrained fn find_treasure_cell(treasure_seed: Field) -> (Field, Field) {
    let mut result_x: Field = 0;
    let mut result_y: Field = 0;
    let mut found = false;
    
    for y in 0..16 {
        for x in 0..16 {
            if !found {
                let cell_hash = std::hash::pedersen_hash([x as Field, y as Field, treasure_seed]);
                let cell_hash_bytes = cell_hash.to_be_bytes::<32>();
                let hash_mod = cell_hash_bytes[31] as u32;
                if hash_mod < TREASURE_THRESHOLD {
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
                let cell_hash = std::hash::pedersen_hash([x as Field, y as Field, treasure_seed]);
                let cell_hash_bytes = cell_hash.to_be_bytes::<32>();
                let hash_mod = cell_hash_bytes[31] as u32;
                if hash_mod >= TREASURE_THRESHOLD {
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
    let artifact_hash = std::hash::pedersen_hash([x, y, treasure_seed, 0x617274696661637400]);
    let artifact_bytes = artifact_hash.to_be_bytes::<32>();
    ((artifact_bytes[31] as u32) % 8) + 1
}

// ============================================================
// Tests
// ============================================================

#[test]
fn test_valid_claim() {
    let treasure_seed: Field = 12345;
    
    // Safety: test-only unconstrained helper to find treasure
    let (x, y) = unsafe { find_treasure_cell(treasure_seed) };
    let salt: Field = 42;

    let commitment = compute_commitment(x, y, salt);
    // Safety: test-only unconstrained helper
    let artifact_id = unsafe { get_artifact_id_unconstrained(x, y, treasure_seed) } as Field;

    main(x, y, salt, commitment, treasure_seed, artifact_id);
}

#[test]
fn test_different_seeds_different_treasures() {
    let seed1: Field = 11111;
    let seed2: Field = 22222;
    
    // Safety: test-only unconstrained helpers
    let (x1, y1) = unsafe { find_treasure_cell(seed1) };
    // Safety: test-only unconstrained helpers
    let (x2, y2) = unsafe { find_treasure_cell(seed2) };
    
    // Just verify both are valid treasures
    assert(is_treasure(x1, y1, seed1));
    assert(is_treasure(x2, y2, seed2));
}

#[test(should_fail_with = "Cell is not a treasure")]
fn test_non_treasure_cell_fails() {
    let treasure_seed: Field = 12345;
    let salt: Field = 42;
    
    // Safety: test-only unconstrained helper
    let (x, y) = unsafe { find_non_treasure_cell(treasure_seed) };

    let commitment = compute_commitment(x, y, salt);
    // Try to claim artifact 1 at non-treasure cell
    main(x, y, salt, commitment, treasure_seed, 1);
}

#[test(should_fail)]
fn test_wrong_commitment_fails() {
    let treasure_seed: Field = 12345;
    // Safety: test-only unconstrained helper
    let (x, y) = unsafe { find_treasure_cell(treasure_seed) };
    let salt: Field = 42;
    // Safety: test-only unconstrained helper
    let artifact_id = unsafe { get_artifact_id_unconstrained(x, y, treasure_seed) } as Field;

    // Wrong commitment - should fail
    main(x, y, salt, 0, treasure_seed, artifact_id);
}

#[test(should_fail)]
fn test_wrong_artifact_id_fails() {
    let treasure_seed: Field = 12345;
    // Safety: test-only unconstrained helper
    let (x, y) = unsafe { find_treasure_cell(treasure_seed) };
    let salt: Field = 42;

    let commitment = compute_commitment(x, y, salt);
    // Safety: test-only unconstrained helper
    let correct_id = unsafe { get_artifact_id_unconstrained(x, y, treasure_seed) };
    // Pick wrong ID
    let wrong_id = if correct_id == 1 { 2 } else { 1 };

    main(x, y, salt, commitment, treasure_seed, wrong_id as Field);
}

#[test(should_fail_with = "X coordinate out of bounds")]
fn test_x_out_of_bounds_fails() {
    let treasure_seed: Field = 12345;
    let salt: Field = 42;
    let x: Field = 16; // Out of bounds
    let y: Field = 5;

    let commitment = compute_commitment(x, y, salt);
    main(x, y, salt, commitment, treasure_seed, 1);
}

#[test(should_fail_with = "Y coordinate out of bounds")]
fn test_y_out_of_bounds_fails() {
    let treasure_seed: Field = 12345;
    let salt: Field = 42;
    let x: Field = 5;
    let y: Field = 20; // Out of bounds

    let commitment = compute_commitment(x, y, salt);
    main(x, y, salt, commitment, treasure_seed, 1);
}
