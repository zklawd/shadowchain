use poseidon::poseidon::bn254::hash_2;
use poseidon::poseidon::bn254::hash_3;

/// Test Poseidon hash compatibility with Solidity
/// We'll hash known values and compare with on-chain results

fn main(
    a: pub Field,
    b: pub Field,
    c: pub Field,
) -> pub (Field, Field) {
    // Hash 2 elements: poseidon(a, b)
    let hash2 = hash_2([a, b]);
    
    // Hash 3 elements: poseidon(a, b, c)  
    let hash3 = hash_3([a, b, c]);
    
    (hash2, hash3)
}

#[test]
fn test_known_values() {
    // Test with simple known values
    let a: Field = 1;
    let b: Field = 2;
    let c: Field = 3;
    
    let (h2, h3) = main(a, b, c);
    
    // Print results (these will be compared with Solidity)
    println(f"poseidon(1, 2) = {h2}");
    println(f"poseidon(1, 2, 3) = {h3}");
}

#[test]
fn test_coordinate_hash() {
    // Simulate hashing coordinates with a seed
    let x: Field = 5;
    let y: Field = 10;
    let seed: Field = 12345; // Simple seed for testing
    
    let cell_hash = hash_3([x, y, seed]);
    println(f"poseidon(5, 10, 12345) = {cell_hash}");
}
