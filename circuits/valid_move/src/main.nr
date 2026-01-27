use std::hash::pedersen_hash;

/// Grid size constant
global GRID_SIZE: u8 = 16;

/// Valid Move Circuit
/// Proves a move from old position to new position is:
///   1. Both commitments are correct
///   2. New position is adjacent (N/S/E/W) or same as old (stay)
///   3. New position is within bounds (0-15)
///   4. New position is not a wall (checked against public map bitmap)
///
/// Private inputs: old_x, old_y, old_salt, new_x, new_y, new_salt
/// Public inputs: old_commitment, new_commitment, map_walls (16 Field values, one per row, each a bitmask)
fn main(
    // Private inputs
    old_x: Field,
    old_y: Field,
    old_salt: Field,
    new_x: Field,
    new_y: Field,
    new_salt: Field,
    // Public inputs
    old_commitment: pub Field,
    new_commitment: pub Field,
    map_walls: pub [Field; 16],
) {
    // 1. Verify both commitments
    let computed_old = pedersen_hash([old_x, old_y, old_salt]);
    assert(computed_old == old_commitment, "Old position commitment mismatch");

    let computed_new = pedersen_hash([new_x, new_y, new_salt]);
    assert(computed_new == new_commitment, "New position commitment mismatch");

    // Cast to integers for arithmetic checks
    let ox = old_x as u8;
    let oy = old_y as u8;
    let nx = new_x as u8;
    let ny = new_y as u8;

    // 2. Bounds check: both positions must be in [0, 15]
    assert(ox < GRID_SIZE, "Old x out of bounds");
    assert(oy < GRID_SIZE, "Old y out of bounds");
    assert(nx < GRID_SIZE, "New x out of bounds");
    assert(ny < GRID_SIZE, "New y out of bounds");

    // 3. Adjacency check: Manhattan distance must be 0 (stay) or 1 (N/S/E/W)
    //    We compute |dx| + |dy| and assert it's <= 1
    //    Since these are unsigned, we compute abs difference carefully
    let dx = if nx >= ox { nx - ox } else { ox - nx };
    let dy = if ny >= oy { ny - oy } else { oy - ny };
    let manhattan = dx + dy;
    assert(manhattan <= 1, "Move is not adjacent (must be N/S/E/W or stay)");

    // 4. Wall check: new position must not be a wall
    //    map_walls[row] is a bitmask where bit `col` = 1 means wall
    //    Check: (map_walls[new_y] >> new_x) & 1 == 0
    let row_bits = map_walls[ny as u32] as u32;
    let bit = (row_bits >> (nx as u32)) & 1;
    assert(bit == 0, "New position is a wall");
}

/// Helper: compute a position commitment
fn compute_commitment(x: Field, y: Field, salt: Field) -> Field {
    pedersen_hash([x, y, salt])
}

/// Helper: create an empty map (no walls)
fn empty_map() -> [Field; 16] {
    [0; 16]
}

#[test]
fn test_valid_move_east() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let old_x: Field = 5;
    let old_y: Field = 5;
    let new_x: Field = 6; // Move east
    let new_y: Field = 5;

    let old_c = compute_commitment(old_x, old_y, old_salt);
    let new_c = compute_commitment(new_x, new_y, new_salt);

    main(old_x, old_y, old_salt, new_x, new_y, new_salt, old_c, new_c, empty_map());
}

#[test]
fn test_valid_move_north() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let old_x: Field = 5;
    let old_y: Field = 5;
    let new_x: Field = 5;
    let new_y: Field = 4; // Move north (y decreases)

    let old_c = compute_commitment(old_x, old_y, old_salt);
    let new_c = compute_commitment(new_x, new_y, new_salt);

    main(old_x, old_y, old_salt, new_x, new_y, new_salt, old_c, new_c, empty_map());
}

#[test]
fn test_valid_move_south() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let old_x: Field = 5;
    let old_y: Field = 5;
    let new_x: Field = 5;
    let new_y: Field = 6; // Move south (y increases)

    let old_c = compute_commitment(old_x, old_y, old_salt);
    let new_c = compute_commitment(new_x, new_y, new_salt);

    main(old_x, old_y, old_salt, new_x, new_y, new_salt, old_c, new_c, empty_map());
}

#[test]
fn test_valid_move_west() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let old_x: Field = 5;
    let old_y: Field = 5;
    let new_x: Field = 4; // Move west
    let new_y: Field = 5;

    let old_c = compute_commitment(old_x, old_y, old_salt);
    let new_c = compute_commitment(new_x, new_y, new_salt);

    main(old_x, old_y, old_salt, new_x, new_y, new_salt, old_c, new_c, empty_map());
}

#[test]
fn test_valid_stay() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let old_x: Field = 5;
    let old_y: Field = 5;

    let old_c = compute_commitment(old_x, old_y, old_salt);
    let new_c = compute_commitment(old_x, old_y, new_salt); // Same position, new salt

    main(old_x, old_y, old_salt, old_x, old_y, new_salt, old_c, new_c, empty_map());
}

#[test(should_fail_with = "Move is not adjacent")]
fn test_diagonal_move_fails() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let old_x: Field = 5;
    let old_y: Field = 5;
    let new_x: Field = 6;
    let new_y: Field = 6; // Diagonal -- invalid

    let old_c = compute_commitment(old_x, old_y, old_salt);
    let new_c = compute_commitment(new_x, new_y, new_salt);

    main(old_x, old_y, old_salt, new_x, new_y, new_salt, old_c, new_c, empty_map());
}

#[test(should_fail_with = "Move is not adjacent")]
fn test_teleport_fails() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let old_x: Field = 0;
    let old_y: Field = 0;
    let new_x: Field = 10;
    let new_y: Field = 10; // Teleport -- invalid

    let old_c = compute_commitment(old_x, old_y, old_salt);
    let new_c = compute_commitment(new_x, new_y, new_salt);

    main(old_x, old_y, old_salt, new_x, new_y, new_salt, old_c, new_c, empty_map());
}

#[test(should_fail_with = "New position is a wall")]
fn test_wall_collision_fails() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let old_x: Field = 5;
    let old_y: Field = 5;
    let new_x: Field = 6; // Move east into a wall
    let new_y: Field = 5;

    let old_c = compute_commitment(old_x, old_y, old_salt);
    let new_c = compute_commitment(new_x, new_y, new_salt);

    // Set wall at (6, 5): row 5, bit 6 = 0b01000000 = 64
    let mut walls = empty_map();
    walls[5] = 64;

    main(old_x, old_y, old_salt, new_x, new_y, new_salt, old_c, new_c, walls);
}

#[test]
fn test_move_at_boundary() {
    // Move from (0,0) to (1,0) -- valid at boundary
    let old_salt: Field = 111;
    let new_salt: Field = 222;

    let old_c = compute_commitment(0, 0, old_salt);
    let new_c = compute_commitment(1, 0, new_salt);

    main(0, 0, old_salt, 1, 0, new_salt, old_c, new_c, empty_map());
}

#[test]
fn test_move_at_max_boundary() {
    // Move from (15,15) to (14,15) -- valid at max boundary
    let old_salt: Field = 111;
    let new_salt: Field = 222;

    let old_c = compute_commitment(15, 15, old_salt);
    let new_c = compute_commitment(14, 15, new_salt);

    main(15, 15, old_salt, 14, 15, new_salt, old_c, new_c, empty_map());
}

#[test(should_fail_with = "Old position commitment mismatch")]
fn test_wrong_old_commitment_fails() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let new_c = compute_commitment(6, 5, new_salt);

    main(5, 5, old_salt, 6, 5, new_salt, 0, new_c, empty_map());
}
