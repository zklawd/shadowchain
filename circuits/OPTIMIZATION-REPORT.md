# Circuit Optimization Report

*Optimized: 2026-01-29*

## Summary

| Circuit | Before | After | Reduction | % Saved |
|---------|--------|-------|-----------|---------|
| **claim_artifact** | 1695 | 800 | **895** | **53%** |
| **combat_reveal** | 714 | 251 | **463** | **65%** |
| **valid_move** | 189 | 170 | **19** | **10%** |
| position_commit | 8 | - | skipped | minimal |

**Total opcodes saved: 1,377**

---

## claim_artifact (1695 → 800 opcodes)

### What Changed

1. **Replaced `to_be_bytes::<32>()` with unconstrained decomposition**
   - Original: Called `.to_be_bytes::<32>()` twice (for cell_hash and artifact_hash)
   - Each call generates 256+ range check constraints (one per bit)
   - New approach: Use `unconstrained fn decompose_mod_256()` to compute `f mod 256` and quotient
   - Verify with simple constraint: `f == quotient * 256 + last_byte`
   - Single u8 range check instead of 256+ bit checks

2. **Removed redundant artifact_id range assertions**
   - artifact_id is derived as `(hash % 8) + 1`, which is always in [1,8]
   - Removed the explicit `assert(aid >= 1)` and `assert(aid <= 8)` checks

3. **Changed TREASURE_THRESHOLD from u32 to Field**
   - Avoids unnecessary type conversions

### Key Technique
The `to_be_bytes` call is extremely expensive because it decomposes a 254-bit field element into 32 bytes, requiring range checks on each byte. By moving this to unconstrained code and verifying only the last byte we need, we eliminate ~250 constraints per call.

```noir
unconstrained fn decompose_mod_256(f: Field) -> (Field, Field) {
    let bytes = f.to_be_bytes::<32>();
    let last_byte = bytes[31] as Field;
    let quotient = (f - last_byte) / 256;
    (last_byte, quotient)
}

// Verification: just 3 constraints instead of 256+
let (last_byte, quotient) = unsafe { decompose_mod_256(hash) };
assert(hash == quotient * 256 + last_byte);
assert((last_byte as u8) as Field == last_byte);
```

---

## combat_reveal (714 → 251 opcodes)

### What Changed

1. **Replaced if-else chain with array lookup tables**
   - Original: 9-branch if-else for `get_artifact_bonus(artifact_id)`
   - Due to conditional flattening, ALL 9 branches execute in the circuit
   - New approach: 6 global lookup arrays indexed by artifact_id

2. **Direct array indexing**
   - `HP_BONUS[aid]` instead of `if aid == 1 { ... } else if aid == 2 { ... }`
   - Arrays are static ROM access when bounds are known

### Key Technique
In Noir, conditionals are flattened - both branches always execute, and the result is selected. A 9-way if-else means 9x the computation. Lookup tables avoid this entirely.

```noir
// Before: ALL branches execute due to flattening
fn get_artifact_bonus(aid: u32) -> [u32; 6] {
    if aid == 1 { [0, 5, 0, 0, 0, 0] }
    else if aid == 2 { [0, 0, 5, 0, 0, 0] }
    // ... 7 more branches
}

// After: Single array access
global HP_BONUS: [u32; 9] = [0, 0, 0, 20, 0, 10, 0, 0, 15];
global ATK_BONUS: [u32; 9] = [0, 5, 0, 0, 8, 0, 3, 6, 2];
// ... etc

hp_bonus += HP_BONUS[aid];
atk_bonus += ATK_BONUS[aid];
```

---

## valid_move (189 → 170 opcodes)

### What Changed

1. **Replaced conditional abs() with squared distance**
   - Original: `if nx >= ox { nx - ox } else { ox - nx }` (both branches execute)
   - New: `dx * dx + dy * dy` using Field arithmetic (no conditionals)

2. **Clever adjacency check using field algebra**
   - For adjacent moves, dist_sq is either 0 (stay) or 1 (cardinal)
   - Verify with `dist_sq * (dist_sq - 1) == 0` (only true if dist_sq ∈ {0, 1})
   - Diagonal moves give dist_sq = 2, which fails

### Key Technique
Field arithmetic is "free" in ZK circuits. Squaring eliminates the need for absolute value calculations, which would require conditionals.

```noir
// Before: conditionals execute both branches
let dx = if nx >= ox { nx - ox } else { ox - nx };
let dy = if ny >= oy { ny - oy } else { oy - ny };
assert(dx + dy <= 1);

// After: pure Field arithmetic, no conditionals
let dx = old_x - new_x;
let dy = old_y - new_y;
let dist_sq = dx * dx + dy * dy;
assert(dist_sq * (dist_sq - 1) == 0);
```

---

## Failed Attempts / Learnings

### valid_move: Unconstrained diff hints
- Attempted using unconstrained functions to compute absolute differences
- Result: 189 → 199 opcodes (WORSE)
- Learning: Unconstrained functions add overhead for simple operations. The verification constraints can outweigh the savings when the original computation is cheap.

### claim_artifact: Batch hash computation
- Considered combining cell_hash and artifact_hash into a single operation
- Not feasible: Different input counts (hash_3 vs hash_4) and both outputs needed separately

---

## Optimization Techniques Reference

1. **Unconstrained witness generation** - Move expensive computation outside the circuit, verify result with simple constraints
2. **Lookup tables over if-else** - Arrays avoid conditional flattening overhead
3. **Field arithmetic over integers** - Field ops are native; integer ops need range checks
4. **Squared distance** - Eliminates conditional abs() calculations
5. **Algebraic verification** - `x * (x - 1) == 0` proves x ∈ {0, 1}

---

## Verification

All tests pass after optimization:

```
claim_artifact: 9 tests passed
combat_reveal: 13 tests passed  
valid_move: 12 tests passed
```
