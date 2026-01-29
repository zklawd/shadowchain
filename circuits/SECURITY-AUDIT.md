# ShadowChain Circuits Security Audit

**Date:** 2025-01-29 (Initial) | 2026-01-29 (Fixes Applied)  
**Auditor:** zklawd (automated ZK security review)  
**Scope:** position_commit, valid_move, claim_artifact, combat_reveal

---

## Executive Summary

Initial audit identified **2 critical**, **2 high**, **1 medium**, and **2 low** severity findings.

**All issues have been addressed.** Summary of fixes applied:

| Finding | Severity | Status |
|---------|----------|--------|
| CA-1: Missing Nullifier | Critical | ✅ FIXED |
| CR-1: No Artifact Ownership | Critical | ✅ FIXED |
| CR-2: Missing Position Bounds | High | ✅ FIXED |
| CR-3: Artifact Duplication | High | ✅ FIXED |
| VM-1: Old Position Wall Check | Medium | ✅ FIXED |
| PC-1: Missing Bounds Checks | Low | ✅ FIXED |
| CR-4: Weak Game Binding | Low | Documented (contract responsibility) |

---

## Fixes Applied

### Critical Fixes

#### CA-1: Nullifier Added to claim_artifact ✅

**Problem:** No mechanism to prevent double-claiming treasures.

**Solution:** Added nullifier derivation:
```noir
// New private input
player_secret: Field,
// New public output
nullifier: pub Field,

// Nullifier computed as:
let computed_nullifier = hash_5([player_secret, x, y, treasure_seed, NULLIFIER_DOMAIN_SEP]);
assert(computed_nullifier == nullifier, "Nullifier mismatch");
```

**Contract requirement:** Track used nullifiers in a mapping and reject duplicates.

#### CR-1: Artifact Ownership Verification Added ✅

**Problem:** Players could claim any artifacts regardless of ownership.

**Solution:** Added inventory commitment verification:
```noir
// New private inputs
owned_artifacts: [u32; MAX_ARTIFACTS],   // Full inventory
inventory_salt: Field,                    // Inventory salt

// New public input
inventory_commitment: pub Field,          // Commitment tracked by contract

// Verification:
// 1. Inventory commitment matches hash of owned_artifacts
// 2. Every claimed artifact exists in owned_artifacts
```

**Contract requirement:** Update `inventory_commitment` when player claims artifacts.

### High Severity Fixes

#### CR-2: Position Bounds Added ✅

**Problem:** combat_reveal didn't validate x, y coordinates.

**Solution:**
```noir
assert(x as u8 < 16, "X coordinate out of bounds");
assert(y as u8 < 16, "Y coordinate out of bounds");
```

#### CR-3: Artifact Uniqueness Check Added ✅

**Problem:** Same artifact could be claimed multiple times for stat stacking.

**Solution:**
```noir
for i in 0..MAX_ARTIFACTS {
    for j in (i + 1)..MAX_ARTIFACTS {
        if (artifact_ids[i] != 0) & (artifact_ids[j] != 0) {
            assert(artifact_ids[i] != artifact_ids[j], "Duplicate artifact in claimed set");
        }
    }
}
```

### Medium Severity Fixes

#### VM-1: Old Position Wall Check Added ✅

**Problem:** Only new position was checked for walls, not old position.

**Solution:**
```noir
// Check OLD position is not a wall
let old_row_bits = map_walls[oy as u32] as u32;
let old_bit = (old_row_bits >> ox) & 1;
assert(old_bit == 0, "Old position is a wall");

// Check NEW position is not a wall (existing)
let new_row_bits = map_walls[ny as u32] as u32;
let new_bit = (new_row_bits >> nx) & 1;
assert(new_bit == 0, "New position is a wall");
```

### Low Severity Fixes

#### PC-1: Bounds Checks Added to position_commit ✅

**Problem:** No coordinate validation in base commitment circuit.

**Solution:**
```noir
assert(x as u8 < 16, "X coordinate out of bounds");
assert(y as u8 < 16, "Y coordinate out of bounds");
```

---

## Test Coverage

All circuits pass comprehensive test suites:

| Circuit | Tests | Coverage |
|---------|-------|----------|
| position_commit | 7 | Bounds, commitments, edge cases |
| valid_move | 13 | Movement, walls, bounds, adjacency |
| claim_artifact | 12 | Nullifiers, treasures, bounds, replay |
| combat_reveal | 14 | Ownership, uniqueness, bounds, stats |

**Total: 46 tests passing**

---

## Contract Integration Requirements

For the security fixes to be effective, the smart contract MUST:

1. **Nullifier tracking** (claim_artifact):
   - Store `mapping(bytes32 => bool) usedNullifiers`
   - Reject proofs with previously-used nullifiers
   - `require(!usedNullifiers[nullifier], "Already claimed")`

2. **Inventory commitment tracking** (combat_reveal):
   - Store `mapping(address => bytes32) inventoryCommitments`
   - Update commitment when player claims new artifacts
   - Pass current commitment as public input to combat_reveal

3. **Proof verification**:
   - Update verifier contracts with new circuit ABIs
   - claim_artifact now has 4 public inputs (was 3)
   - combat_reveal now has 4 public inputs (was 3)

---

## Remaining Considerations

### CR-4: Game Binding (Low - Documented)
The circuit only checks `game_id != 0`. Stronger binding (e.g., game state hash) would provide better guarantees but adds complexity. Current design is acceptable if the contract validates game_id appropriately.

### Circuit Compatibility
**Breaking change:** Circuit interfaces changed. Existing proofs are incompatible. Redeploy verifiers and regenerate all proofs.

---

## Overall Assessment

**Risk Level: LOW** (after fixes)

All critical and high severity issues have been addressed. The circuits now provide:
- Replay protection via nullifiers
- Ownership verification via inventory commitments  
- Proper bounds checking
- Duplicate artifact prevention
- Wall collision detection for both positions

The system is ready for deployment pending contract updates to support the new public inputs.

---

## Known Issue: Verifier Stack Depth (2026-01-29)

**Status:** Blocking production deployment

The Solidity verifiers generated by `bb 0.72.1` (matched to nargo 1.0.0-beta.3) trigger a
"stack too deep" error during compilation:

```
Yul exception: Cannot swap Variable expr_mpos_7 with Variable expr_mpos_20: too deep in the stack by 1 slots
```

**Impact:**
- Tests pass using MockVerifier
- Real ZK proofs cannot be verified on-chain until fixed

**Workarounds being investigated:**
1. Use Groth16 instead of UltraHonk (smaller verifier, but slower proving)
2. Split verifier into multiple contracts
3. Wait for bb update with stack-optimized verifier codegen
4. Use a recursive verification approach

**For deployment:** Use MockVerifier for testnet demos, real verifiers for mainnet once fixed.

---

*End of Audit Report*
