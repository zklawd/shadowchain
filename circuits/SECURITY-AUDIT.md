# ShadowChain Circuits Security Audit

**Date:** 2025-01-29  
**Auditor:** zklawd (automated ZK security review)  
**Scope:** position_commit, valid_move, claim_artifact, combat_reveal

---

## Executive Summary

This audit identified **2 critical**, **2 high**, **1 medium**, and **2 low** severity findings across the four ShadowChain circuits. The most severe issues involve missing nullifier mechanisms and lack of artifact ownership verification, which could allow players to cheat the game mechanics.

| Severity | Count |
|----------|-------|
| Critical | 2 |
| High | 2 |
| Medium | 1 |
| Low | 2 |
| Info | 3 |

---

## Circuit 1: position_commit

**Opcodes:** 8  
**Purpose:** Simple hash commitment proving knowledge of (x, y, salt)

### Findings

#### [LOW] PC-1: Missing Coordinate Range Checks

**Severity:** Low  
**Status:** Confirmed

**Description:**  
The circuit accepts arbitrary Field values for `x` and `y` without constraining them to valid grid coordinates (0-15). While this circuit is primarily used as a building block, a standalone proof could commit to positions outside the valid game grid.

```noir
// Current - x, y are unconstrained Field values
fn main(x: Field, y: Field, salt: Field, commitment: pub Field) {
    let computed = pedersen_hash([x, y, salt]);
    assert(computed == commitment, "Position commitment mismatch");
}
```

**Impact:**  
In isolation, this is low risk since downstream circuits (valid_move, claim_artifact) perform their own bounds checks. However, if this circuit is used independently for position proofs, invalid positions could be committed.

**Recommendation:**  
Add bounds checking for defense-in-depth:
```noir
let x_u8 = x as u8;
let y_u8 = y as u8;
assert(x_u8 < 16, "X out of bounds");
assert(y_u8 < 16, "Y out of bounds");
```

---

## Circuit 2: valid_move

**Opcodes:** 189  
**Purpose:** Validates movement between adjacent cells with wall collision

### Findings

#### [MEDIUM] VM-1: Old Position Not Checked for Walls

**Severity:** Medium  
**Status:** Confirmed

**Description:**  
The circuit only verifies that the NEW position is not a wall, but does not validate that the OLD position is also a valid (non-wall) cell. A malicious prover could generate a proof claiming to move FROM a wall cell.

```noir
// Only new position is checked:
let row_bits = map_walls[ny as u32] as u32;
let bit = (row_bits >> (nx as u8)) & 1;
assert(bit == 0, "New position is a wall");
// OLD position wall check is MISSING
```

**Impact:**  
While the game client would need to accept a previous invalid commitment to be at a wall position initially, if such a state were achieved (e.g., through contract upgrade or bug), the player could exploit this to escape from walls. The attack surface depends on how position commitments are first established.

**Recommendation:**  
Add wall check for old position:
```noir
let old_row_bits = map_walls[oy as u32] as u32;
let old_bit = (old_row_bits >> (ox as u8)) & 1;
assert(old_bit == 0, "Old position is a wall");
```

---

#### [INFO] VM-2: Good Practice - Map Hash Binding

**Severity:** Info  
**Status:** N/A

The circuit correctly binds the proof to a specific map configuration via `map_hash`, preventing provers from using a modified wall layout.

---

## Circuit 3: claim_artifact

**Opcodes:** 1695  
**Purpose:** Proves player is at a procedurally-generated treasure cell

### Findings

#### [CRITICAL] CA-1: Missing Nullifier - Replay Attack Vulnerability

**Severity:** Critical  
**Status:** Confirmed

**Description:**  
The circuit has **no nullifier mechanism** to prevent the same treasure from being claimed multiple times by the same player or different players. Once a valid proof is generated for a treasure cell, it can be reused indefinitely.

```noir
// Current - no nullifier output
fn main(
    x: Field, y: Field, salt: Field,
    commitment: pub Field,
    treasure_seed: pub Field,
    artifact_id: pub Field,
) {
    // ... verifies position and treasure validity
    // BUT no nullifier is computed or returned!
}
```

**Attack Scenario:**
1. Player A generates a proof for treasure at (14, 1)
2. Player A submits proof and claims artifact
3. Player A resubmits the SAME proof again → claims another artifact
4. Repeat infinitely for unlimited artifacts

**Impact:**  
**Complete game economy break.** Players can farm unlimited artifacts, destroying the in-game economy and any competitive integrity.

**Recommendation:**  
Add a nullifier that commits to the player's identity and the specific treasure:
```noir
// Add player_address or player_id as private input
// Add nullifier as public output
fn main(
    x: Field, y: Field, salt: Field,
    player_secret: Field,  // NEW: player's secret
    commitment: pub Field,
    treasure_seed: pub Field,
    artifact_id: pub Field,
    nullifier: pub Field,  // NEW: prevents double-claiming
) {
    // ... existing checks ...
    
    // Nullifier binds player to this specific treasure location
    let computed_nullifier = poseidon([player_secret, x, y, treasure_seed]);
    assert(computed_nullifier == nullifier, "Invalid nullifier");
}
```

The contract must then track used nullifiers and reject duplicates.

---

#### [INFO] CA-2: Good Practice - Domain Separation

**Severity:** Info  
**Status:** N/A

The circuit correctly uses `ARTIFACT_DOMAIN_SEP` for artifact ID derivation, preventing hash collision attacks between different hash usages.

---

## Circuit 4: combat_reveal

**Opcodes:** 714  
**Purpose:** Proves player stats are correctly derived from base + artifacts

### Findings

#### [CRITICAL] CR-1: No Artifact Ownership Verification

**Severity:** Critical  
**Status:** Confirmed

**Description:**  
The circuit accepts any `artifact_ids` array without verifying that the player actually owns those artifacts. A malicious prover can claim to possess any combination of artifacts they never collected.

```noir
fn main(
    // ...
    artifact_ids: [u32; MAX_ARTIFACTS],  // Completely unconstrained!
    // ...
) {
    for i in 0..MAX_ARTIFACTS {
        let aid = artifact_ids[i];
        assert(aid <= 8, "Invalid artifact ID");  // Only checks range, not ownership
        // ... applies bonuses
    }
}
```

**Attack Scenario:**
1. Player has no artifacts
2. Player generates combat_reveal proof claiming `[1, 2, 3, 4, 5, 6, 7, 8]` (all artifacts)
3. Circuit computes inflated stats: HP=135, ATK=33, DEF=20
4. Player dominates combat with fake stats

**Impact:**  
**Complete combat system compromise.** Any player can claim maximum stats regardless of actual progression.

**Recommendation:**  
The circuit needs to verify artifact ownership. Options:

**Option A: Merkle Proof of Inventory**
```noir
// Add merkle root of player's inventory as public input
// Add merkle proofs for each claimed artifact
inventory_root: pub Field,
merkle_paths: [[Field; TREE_DEPTH]; MAX_ARTIFACTS],
```

**Option B: Commitment to Artifact Set**
```noir
// Player commits to their artifact set when collecting
// Circuit verifies the commitment matches claimed artifacts
artifact_set_commitment: pub Field,
artifact_set_salt: Field,
// ...
let computed_set = poseidon([...artifact_ids, artifact_set_salt]);
assert(computed_set == artifact_set_commitment);
```

---

#### [HIGH] CR-2: Missing Position Bounds Check

**Severity:** High  
**Status:** Confirmed

**Description:**  
Unlike other circuits, combat_reveal does not validate that `x` and `y` are within the valid grid (0-15). Arbitrary Field values can be used for the position.

```noir
fn main(
    x: Field,  // No bounds check!
    y: Field,  // No bounds check!
    // ...
)
```

**Impact:**  
If the commitment scheme or other circuits rely on positions being bounded, this inconsistency could lead to unexpected behavior. While the commitment itself binds the position, the lack of bounds validation is a defense-in-depth failure.

**Recommendation:**  
Add explicit bounds checks:
```noir
let x_u8 = x as u8;
let y_u8 = y as u8;
assert(x_u8 < 16, "X out of bounds");
assert(y_u8 < 16, "Y out of bounds");
```

---

#### [HIGH] CR-3: Artifact Duplication Allowed

**Severity:** High  
**Status:** Confirmed (possibly intentional)

**Description:**  
The circuit allows the same artifact ID to appear multiple times in the array, enabling stat stacking. The test `test_duplicate_artifacts` explicitly demonstrates this:

```noir
#[test]
fn test_duplicate_artifacts() {
    // Two Shadow Blades: HP=100, ATK=10+5+5=20, DEF=5
    let artifacts: [u32; MAX_ARTIFACTS] = [1, 1, 0, 0, 0, 0, 0, 0];
    // ...
}
```

**Impact:**  
If not intended, players could stack the same artifact's bonuses 8 times:
- 8x Shadow Blade: +40 ATK
- 8x Vitality Amulet: +160 HP

**Recommendation:**  
If duplicates should be disallowed, add uniqueness check:
```noir
for i in 0..MAX_ARTIFACTS {
    for j in (i + 1)..MAX_ARTIFACTS {
        if artifact_ids[i] != 0 && artifact_ids[j] != 0 {
            assert(artifact_ids[i] != artifact_ids[j], "Duplicate artifact");
        }
    }
}
```

If duplicates ARE intended (rare drops of same type), document this explicitly.

---

#### [LOW] CR-4: game_id Zero Check Only

**Severity:** Low  
**Status:** Confirmed

**Description:**  
The circuit only checks that `game_id != 0`. It doesn't bind the proof to any specific game state or verify the game exists.

```noir
assert(game_id != 0, "Invalid game ID");
```

**Impact:**  
Low, since the contract likely validates game_id separately. However, the circuit alone provides weak game binding.

**Recommendation:**  
Consider binding to game state hash for stronger guarantees:
```noir
game_state_hash: pub Field,  // Hash of relevant game state
```

---

#### [INFO] CR-5: Good Practice - Underflow Protection

**Severity:** Info  
**Status:** N/A

The circuit properly handles negative stat modifiers using separate bonus/penalty tracking and floor values, preventing u32 underflow:
```noir
let hp = if raw_hp > hp_penalty {
    let result = raw_hp - hp_penalty;
    if result < 1 { 1 } else { result }
} else {
    1
};
```

---

## Summary of Recommendations

### Critical (Must Fix)

1. **CA-1:** Add nullifier mechanism to claim_artifact to prevent replay attacks
2. **CR-1:** Add artifact ownership verification to combat_reveal

### High (Should Fix)

3. **CR-2:** Add position bounds checks to combat_reveal
4. **CR-3:** Add artifact uniqueness check OR document that duplicates are intentional

### Medium (Consider Fixing)

5. **VM-1:** Add old position wall check to valid_move

### Low (Optional)

6. **PC-1:** Add bounds checks to position_commit for defense-in-depth
7. **CR-4:** Consider stronger game binding than just game_id != 0

---

## Testing Recommendations

The circuits have good "should fail" tests. Additional tests recommended:

1. **Replay test for claim_artifact:** Verify contract rejects duplicate proofs (requires nullifier)
2. **Fake inventory test for combat_reveal:** Verify contract cross-checks artifact ownership
3. **Edge case: 8 identical artifacts** - Verify expected behavior
4. **Edge case: Maximum negative modifiers** - Verify stats don't underflow below floors
5. **Fuzz testing:** Random valid/invalid inputs to find edge cases

---

## Overall Assessment

**Risk Level: HIGH**

The circuits demonstrate solid understanding of ZK constraint systems and include good practices like:
- Commitment verification
- Domain separation
- Map hash binding
- Underflow protection

However, the **two critical findings** (missing nullifier in claim_artifact, missing ownership check in combat_reveal) represent fundamental design gaps that would allow complete exploitation of game mechanics. These must be addressed before deployment.

The architecture assumes the smart contract will enforce rules the circuits don't verify. This is a valid pattern, but creates a critical dependency on contract correctness. Consider whether moving more validation into circuits would improve security guarantees.

---

*End of Audit Report*
