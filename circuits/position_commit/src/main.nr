use std::hash::pedersen_hash;

/// Position Commitment Circuit
/// Proves: commitment = hash(x, y, salt)
/// Private inputs: x, y, salt
/// Public inputs: commitment
fn main(x: Field, y: Field, salt: Field, commitment: pub Field) {
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
