use std::hash::pedersen_hash;

/// Position Commitment Circuit
/// Proves: commitment = hash(x, y, salt)
/// Private inputs: x, y, salt
/// Public inputs: commitment
fn main(x: Field, y: Field, salt: Field, commitment: pub Field) {
    let computed = pedersen_hash([x, y, salt]);
    assert(computed == commitment, "Position commitment mismatch");
}
