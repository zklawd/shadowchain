use std::hash::pedersen_hash;

/// Grid size constant
global GRID_SIZE: u8 = 16;

/// Valid Move Circuit (SECURED with game binding)
/// Proves a move from old position to new position is:
///   1. Both commitments are correct
///   2. New position is adjacent (N/S/E/W) or same as old (stay)
///   3. New position is within bounds (0-15)
///   4. New position is not a wall (verified via map_hash binding)
///   5. Move is bound to a specific game (prevents cross-game replay)
///
/// Private inputs: old_x, old_y, old_salt, new_x, new_y, new_salt, map_walls[16]
/// Public inputs: old_commitment, new_commitment, map_hash, game_id
fn main(
    // Private inputs
    old_x: Field,
    old_y: Field,
    old_salt: Field,
    new_x: Field,
    new_y: Field,
    new_salt: Field,
    map_walls: [Field; 16],
    // Public inputs (4 total - added game_id for H-03)
    old_commitment: pub Field,
    new_commitment: pub Field,
    map_hash: pub Field,
    game_id: pub Field,  // NEW: Binds proof to specific game
) {
    // SECURITY FIX (H-03): Verify game_id is valid (non-zero)
    // The contract MUST verify game_id matches the actual game
    assert(game_id != 0, "Invalid game ID");
    // 1. Verify map integrity - prover must use the real map
    let computed_map_hash = pedersen_hash(map_walls);
    assert(computed_map_hash == map_hash, "Map hash mismatch");

    // 2. Verify both commitments
    let computed_old = pedersen_hash([old_x, old_y, old_salt]);
    assert(computed_old == old_commitment, "Old position commitment mismatch");

    let computed_new = pedersen_hash([new_x, new_y, new_salt]);
    assert(computed_new == new_commitment, "New position commitment mismatch");

    // Cast to integers for arithmetic checks
    let ox = old_x as u8;
    let oy = old_y as u8;
    let nx = new_x as u8;
    let ny = new_y as u8;

    // 3. Bounds check: both positions must be in [0, 15]
    assert(ox < GRID_SIZE, "Old x out of bounds");
    assert(oy < GRID_SIZE, "Old y out of bounds");
    assert(nx < GRID_SIZE, "New x out of bounds");
    assert(ny < GRID_SIZE, "New y out of bounds");

    // 4. Adjacency check: Manhattan distance must be 0 (stay) or 1 (N/S/E/W)
    // Using squared differences to avoid conditionals for abs value
    // (dx)^2 + (dy)^2 <= 1 since we only allow moves of 0 or 1 in each dimension
    // and diagonal moves (1,1) give 2 which fails
    let dx = old_x - new_x;
    let dy = old_y - new_y;
    let dist_sq = dx * dx + dy * dy;
    
    // dist_sq must be 0 (stay) or 1 (cardinal move)
    // In a prime field, checking dist_sq * (dist_sq - 1) == 0 verifies dist_sq in {0, 1}
    assert(dist_sq * (dist_sq - 1) == 0, "Move is not adjacent (must be N/S/E/W or stay)");

    // 5. Wall check: BOTH positions must not be walls
    //    (defense-in-depth: prevents exploits if player somehow committed to wall position)
    
    // Check OLD position is not a wall
    let old_row_bits = map_walls[oy as u32] as u32;
    let old_bit = (old_row_bits >> ox) & 1;
    assert(old_bit == 0, "Old position is a wall");
    
    // Check NEW position is not a wall
    let new_row_bits = map_walls[ny as u32] as u32;
    let new_bit = (new_row_bits >> nx) & 1;
    assert(new_bit == 0, "New position is a wall");
}

/// Helper: compute a position commitment
fn compute_commitment(x: Field, y: Field, salt: Field) -> Field {
    pedersen_hash([x, y, salt])
}

/// Helper: create an empty map (no walls)
fn empty_map() -> [Field; 16] {
    [0; 16]
}

/// Helper: compute map hash from wall rows
fn compute_map_hash(walls: [Field; 16]) -> Field {
    pedersen_hash(walls)
}

#[test]
fn test_valid_move_east() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let game_id: Field = 1;
    let walls = empty_map();
    let mh = compute_map_hash(walls);

    let old_c = compute_commitment(5, 5, old_salt);
    let new_c = compute_commitment(6, 5, new_salt);

    main(5, 5, old_salt, 6, 5, new_salt, walls, old_c, new_c, mh, game_id);
}

#[test]
fn test_valid_move_north() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let game_id: Field = 42;
    let walls = empty_map();
    let mh = compute_map_hash(walls);

    let old_c = compute_commitment(5, 5, old_salt);
    let new_c = compute_commitment(5, 4, new_salt);

    main(5, 5, old_salt, 5, 4, new_salt, walls, old_c, new_c, mh, game_id);
}

#[test]
fn test_valid_move_south() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let game_id: Field = 99;
    let walls = empty_map();
    let mh = compute_map_hash(walls);

    let old_c = compute_commitment(5, 5, old_salt);
    let new_c = compute_commitment(5, 6, new_salt);

    main(5, 5, old_salt, 5, 6, new_salt, walls, old_c, new_c, mh, game_id);
}

#[test]
fn test_valid_move_west() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let game_id: Field = 7;
    let walls = empty_map();
    let mh = compute_map_hash(walls);

    let old_c = compute_commitment(5, 5, old_salt);
    let new_c = compute_commitment(4, 5, new_salt);

    main(5, 5, old_salt, 4, 5, new_salt, walls, old_c, new_c, mh, game_id);
}

#[test]
fn test_valid_stay() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let game_id: Field = 123;
    let walls = empty_map();
    let mh = compute_map_hash(walls);

    let old_c = compute_commitment(5, 5, old_salt);
    let new_c = compute_commitment(5, 5, new_salt);

    main(5, 5, old_salt, 5, 5, new_salt, walls, old_c, new_c, mh, game_id);
}

#[test(should_fail_with = "Move is not adjacent")]
fn test_diagonal_move_fails() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let game_id: Field = 1;
    let walls = empty_map();
    let mh = compute_map_hash(walls);

    let old_c = compute_commitment(5, 5, old_salt);
    let new_c = compute_commitment(6, 6, new_salt);

    main(5, 5, old_salt, 6, 6, new_salt, walls, old_c, new_c, mh, game_id);
}

#[test(should_fail_with = "Move is not adjacent")]
fn test_teleport_fails() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let game_id: Field = 1;
    let walls = empty_map();
    let mh = compute_map_hash(walls);

    let old_c = compute_commitment(0, 0, old_salt);
    let new_c = compute_commitment(10, 10, new_salt);

    main(0, 0, old_salt, 10, 10, new_salt, walls, old_c, new_c, mh, game_id);
}

#[test(should_fail_with = "New position is a wall")]
fn test_wall_collision_fails() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let game_id: Field = 1;

    // Set wall at (6, 5): row 5, bit 6 = 64
    let mut walls = empty_map();
    walls[5] = 64;
    let mh = compute_map_hash(walls);

    let old_c = compute_commitment(5, 5, old_salt);
    let new_c = compute_commitment(6, 5, new_salt);

    main(5, 5, old_salt, 6, 5, new_salt, walls, old_c, new_c, mh, game_id);
}

#[test(should_fail_with = "Map hash mismatch")]
fn test_wrong_map_hash_fails() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let game_id: Field = 1;
    let walls = empty_map();

    let old_c = compute_commitment(5, 5, old_salt);
    let new_c = compute_commitment(6, 5, new_salt);

    // Pass wrong map hash
    main(5, 5, old_salt, 6, 5, new_salt, walls, old_c, new_c, 0, game_id);
}

#[test]
fn test_move_at_boundary() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let game_id: Field = 5;
    let walls = empty_map();
    let mh = compute_map_hash(walls);

    let old_c = compute_commitment(0, 0, old_salt);
    let new_c = compute_commitment(1, 0, new_salt);

    main(0, 0, old_salt, 1, 0, new_salt, walls, old_c, new_c, mh, game_id);
}

#[test]
fn test_move_at_max_boundary() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let game_id: Field = 999;
    let walls = empty_map();
    let mh = compute_map_hash(walls);

    let old_c = compute_commitment(15, 15, old_salt);
    let new_c = compute_commitment(14, 15, new_salt);

    main(15, 15, old_salt, 14, 15, new_salt, walls, old_c, new_c, mh, game_id);
}

#[test(should_fail_with = "Old position commitment mismatch")]
fn test_wrong_old_commitment_fails() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let game_id: Field = 1;
    let walls = empty_map();
    let mh = compute_map_hash(walls);
    let new_c = compute_commitment(6, 5, new_salt);

    main(5, 5, old_salt, 6, 5, new_salt, walls, 0, new_c, mh, game_id);
}

#[test(should_fail_with = "Old position is a wall")]
fn test_old_position_wall_fails() {
    // Security test: if somehow player committed to a wall position,
    // they should not be able to move from it
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let game_id: Field = 1;

    // Set wall at (5, 5): row 5, bit 5 = 32
    let mut walls = empty_map();
    walls[5] = 32;
    let mh = compute_map_hash(walls);

    // Old position (5,5) is a wall, new position (6,5) is not
    let old_c = compute_commitment(5, 5, old_salt);
    let new_c = compute_commitment(6, 5, new_salt);

    main(5, 5, old_salt, 6, 5, new_salt, walls, old_c, new_c, mh, game_id);
}

#[test(should_fail_with = "Invalid game ID")]
fn test_zero_game_id_fails() {
    let old_salt: Field = 111;
    let new_salt: Field = 222;
    let walls = empty_map();
    let mh = compute_map_hash(walls);

    let old_c = compute_commitment(5, 5, old_salt);
    let new_c = compute_commitment(6, 5, new_salt);

    // game_id = 0 should fail
    main(5, 5, old_salt, 6, 5, new_salt, walls, old_c, new_c, mh, 0);
}
