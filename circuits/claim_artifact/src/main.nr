use std::hash::pedersen_hash;

/// Claim Artifact Circuit
/// Proves a player is at a specific treasure cell without revealing position.
///
/// Private inputs: x, y, salt
/// Public inputs: commitment, artifact_cell_hash, artifact_id
///
/// Proves:
///   1. commitment = hash(x, y, salt)  -- player knows their position
///   2. hash(x, y) = artifact_cell_hash -- player is at the treasure cell
fn main(
    // Private inputs
    x: Field,
    y: Field,
    salt: Field,
    // Public inputs
    commitment: pub Field,
    artifact_cell_hash: pub Field,
    artifact_id: pub Field,
) {
    // 1. Verify position commitment
    let computed_commitment = pedersen_hash([x, y, salt]);
    assert(computed_commitment == commitment, "Position commitment mismatch");

    // 2. Verify player is at the artifact cell
    //    artifact_cell_hash = hash(x, y) -- no salt, so the contract can compute this
    //    for known treasure locations
    let computed_cell_hash = pedersen_hash([x, y]);
    assert(computed_cell_hash == artifact_cell_hash, "Player is not at artifact cell");

    // artifact_id is a public input that identifies which artifact is being claimed.
    // The contract uses it to track claims. We constrain it to be non-zero.
    assert(artifact_id != 0, "Invalid artifact ID");
}

/// Helper: compute a position commitment
fn compute_commitment(x: Field, y: Field, salt: Field) -> Field {
    pedersen_hash([x, y, salt])
}

/// Helper: compute a cell hash (no salt -- public knowledge for known cells)
fn compute_cell_hash(x: Field, y: Field) -> Field {
    pedersen_hash([x, y])
}

#[test]
fn test_valid_claim() {
    let x: Field = 10;
    let y: Field = 3;
    let salt: Field = 42;
    let artifact_id: Field = 1;

    let commitment = compute_commitment(x, y, salt);
    let cell_hash = compute_cell_hash(x, y);

    main(x, y, salt, commitment, cell_hash, artifact_id);
}

#[test]
fn test_claim_different_artifact() {
    let x: Field = 7;
    let y: Field = 12;
    let salt: Field = 9999;
    let artifact_id: Field = 5;

    let commitment = compute_commitment(x, y, salt);
    let cell_hash = compute_cell_hash(x, y);

    main(x, y, salt, commitment, cell_hash, artifact_id);
}

#[test]
fn test_claim_at_boundary() {
    let x: Field = 0;
    let y: Field = 15;
    let salt: Field = 777;
    let artifact_id: Field = 3;

    let commitment = compute_commitment(x, y, salt);
    let cell_hash = compute_cell_hash(x, y);

    main(x, y, salt, commitment, cell_hash, artifact_id);
}

#[test(should_fail_with = "Player is not at artifact cell")]
fn test_wrong_cell_fails() {
    let x: Field = 10;
    let y: Field = 3;
    let salt: Field = 42;
    let artifact_id: Field = 1;

    let commitment = compute_commitment(x, y, salt);
    // Wrong cell hash -- artifact is at (5, 5), player is at (10, 3)
    let wrong_cell_hash = compute_cell_hash(5, 5);

    main(x, y, salt, commitment, wrong_cell_hash, artifact_id);
}

#[test(should_fail_with = "Position commitment mismatch")]
fn test_wrong_commitment_fails() {
    let x: Field = 10;
    let y: Field = 3;
    let salt: Field = 42;
    let artifact_id: Field = 1;

    let cell_hash = compute_cell_hash(x, y);

    // Wrong commitment
    main(x, y, salt, 0, cell_hash, artifact_id);
}

#[test(should_fail_with = "Invalid artifact ID")]
fn test_zero_artifact_id_fails() {
    let x: Field = 10;
    let y: Field = 3;
    let salt: Field = 42;

    let commitment = compute_commitment(x, y, salt);
    let cell_hash = compute_cell_hash(x, y);

    main(x, y, salt, commitment, cell_hash, 0);
}
