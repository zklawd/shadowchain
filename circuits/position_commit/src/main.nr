use std::hash::pedersen_hash;

/// Grid size for bounds checking
global GRID_SIZE: u8 = 16;

/// Position Commitment Circuit (SECURED with bounds checks)
/// Proves: commitment = hash(x, y, salt) AND position is valid
/// Private inputs: x, y, salt
/// Public inputs: commitment
///
/// SECURITY: Validates coordinates are within grid bounds (0-15)
/// This provides defense-in-depth even though downstream circuits also check bounds.
fn main(x: Field, y: Field, salt: Field, commitment: pub Field) {
    // Bounds check: position must be in valid grid (0-15)
    let x_u8 = x as u8;
    let y_u8 = y as u8;
    assert(x_u8 < GRID_SIZE, "X coordinate out of bounds");
    assert(y_u8 < GRID_SIZE, "Y coordinate out of bounds");
    
    // Commitment verification
    let computed = pedersen_hash([x, y, salt]);
    assert(computed == commitment, "Position commitment mismatch");
}

/// Helper: compute a position commitment (for use in tests)
fn compute_commitment(x: Field, y: Field, salt: Field) -> Field {
    pedersen_hash([x, y, salt])
}

#[test]
fn test_valid_commitment() {
    let x: Field = 3;
    let y: Field = 7;
    let salt: Field = 12345;
    let commitment = compute_commitment(x, y, salt);
    main(x, y, salt, commitment);
}

#[test]
fn test_different_positions_different_commitments() {
    let salt: Field = 99;
    let c1 = compute_commitment(0, 0, salt);
    let c2 = compute_commitment(1, 0, salt);
    let c3 = compute_commitment(0, 1, salt);
    assert(c1 != c2);
    assert(c1 != c3);
    assert(c2 != c3);
}

#[test]
fn test_different_salts_different_commitments() {
    let c1 = compute_commitment(5, 5, 100);
    let c2 = compute_commitment(5, 5, 200);
    assert(c1 != c2);
}

#[test(should_fail_with = "Position commitment mismatch")]
fn test_wrong_commitment_fails() {
    main(3, 7, 12345, 0);
}

#[test(should_fail_with = "X coordinate out of bounds")]
fn test_x_out_of_bounds_fails() {
    let x: Field = 16; // Out of bounds
    let y: Field = 5;
    let salt: Field = 42;
    let commitment = compute_commitment(x, y, salt);
    main(x, y, salt, commitment);
}

#[test(should_fail_with = "Y coordinate out of bounds")]
fn test_y_out_of_bounds_fails() {
    let x: Field = 5;
    let y: Field = 20; // Out of bounds
    let salt: Field = 42;
    let commitment = compute_commitment(x, y, salt);
    main(x, y, salt, commitment);
}

#[test]
fn test_boundary_positions_valid() {
    // Test edge cases: (0,0), (15,15), (0,15), (15,0)
    let salt: Field = 777;
    
    let c1 = compute_commitment(0, 0, salt);
    main(0, 0, salt, c1);
    
    let c2 = compute_commitment(15, 15, salt);
    main(15, 15, salt, c2);
    
    let c3 = compute_commitment(0, 15, salt);
    main(0, 15, salt, c3);
    
    let c4 = compute_commitment(15, 0, salt);
    main(15, 0, salt, c4);
}
