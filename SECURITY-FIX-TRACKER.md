# Security Fix Tracker

**Started:** 2026-01-29 ~07:00 UTC
**Status:** IN PROGRESS

## Critical Issues

| ID | Issue | Branch | Status | Notes |
|----|-------|--------|--------|-------|
| C-01 | claim_artifact missing treasure validation | `fix/c02-nullifier-and-ownership` | ✅ FIXED | Included in circuit restore (Poseidon hash check) |
| C-02 | Circuit/contract nullifier mismatch | `fix/c02-nullifier-and-ownership` | ✅ FIXED | Restored secured circuits from 087b147 |
| C-03 | combat_reveal no co-location proof | `fix/c03-combat-colocation` | ⏳ PENDING | |

## High Issues

| ID | Issue | Branch | Status | Notes |
|----|-------|--------|--------|-------|
| H-01 | submitMove no public input validation | `fix/c02-nullifier-and-ownership` | ✅ FIXED | Added public input validation in submitMove |
| H-02 | ArtifactRegistry no access control | `fix/c02-nullifier-and-ownership` | ✅ FIXED | Added onlyGame modifier |
| H-03 | No game_id in move proofs | `fix/c02-nullifier-and-ownership` | ✅ FIXED | Added game_id to valid_move circuit |
| H-04 | combat_reveal allows duplicate artifacts | `fix/c02-nullifier-and-ownership` | ✅ FIXED | Included in circuit restore |

## Medium Issues

| ID | Issue | Branch | Status | Notes |
|----|-------|--------|--------|-------|
| M-01 | Treasure location front-running | `fix/m01-commit-reveal` | ⏳ PENDING | |
| M-02 | Weak combat randomness | `fix/m02-randomness` | ⏳ PENDING | |
| M-03 | position_commit no bounds | `fix/c02-nullifier-and-ownership` | ✅ FIXED | Bounds checks added to position_commit |
| M-04 | Prize griefing | `fix/m04-pull-payment` | ⏳ PENDING | |
| M-05 | setMapHash no access control | `fix/c02-nullifier-and-ownership` | ✅ FIXED | Added creator-only check |

## Workflow Per Issue

1. Create branch from main
2. Implement fix in circuit and/or contract
3. Add/update Noir tests
4. Run `nargo test` - all must pass
5. Run hardhat-noir E2E tests
6. Update CIRCUIT_INTERFACES.md if interface changed
7. Document changes in this file
8. Commit with clear message

## Priority Order

1. **C-02** first (circuit/contract mismatch is blocking everything)
2. **C-01** (treasure validation)
3. **H-04** (artifact uniqueness - related to C-02)
4. **H-01** (move validation)
5. **H-02** (registry access control)
6. **H-03** (game binding)
7. **C-03** (combat co-location - complex, needs design)
8. **M-03** (position bounds)
9. **M-05** (maphash access)
10. **M-04** (pull payment)
11. **M-01** (commit-reveal - major refactor)
12. **M-02** (randomness - needs VRF integration)

## Completion Log

### 2026-01-29 ~07:30 UTC - C-02, H-04, M-03 (Circuit Restore)

**Branch:** `fix/c02-nullifier-and-ownership`

**Changes:**
1. **claim_artifact** circuit restored with:
   - `player_secret` (private) for nullifier derivation
   - `nullifier` (public) to prevent double-claiming
   - Poseidon-based treasure verification
   - Coordinate bounds checks (0-15)

2. **combat_reveal** circuit restored with:
   - `owned_artifacts[8]` (private) - player's full inventory
   - `inventory_salt` (private) - salt for inventory commitment
   - `inventory_commitment` (public) - proves artifact ownership
   - Artifact uniqueness check (no duplicates)
   - Position bounds checks (0-15)

3. **valid_move** circuit restored with:
   - Old position wall check (defense-in-depth)
   - Both positions bounds checked

4. **position_commit** circuit restored with:
   - Coordinate bounds checks (0-15)

5. Created **CIRCUIT_INTERFACES.md** documenting all circuit interfaces

**Test Results:**
- claim_artifact: 12 tests passed
- combat_reveal: 14 tests passed  
- valid_move: 13 tests passed
- position_commit: 7 tests passed
- **Total: 46 tests passed**

**Next Steps:**
- Verifiers must be regenerated

---

### 2026-01-29 ~07:45 UTC - H-01, H-02, M-05 (Contract Fixes)

**Changes:**

1. **ShadowChainGame.sol - submitMove (H-01)**:
   - Added validation that public inputs match on-chain state
   - `publicInputs[0]` must match player's current commitment
   - `publicInputs[1]` must match the new commitment parameter
   - `publicInputs[2]` must match the game's stored map hash
   - Prevents proof substitution attacks

2. **ShadowChainGame.sol - setMapHash (M-05)**:
   - Added `msg.sender == g.creator` check
   - Only game creator can set the map hash
   - Prevents malicious map hash manipulation

3. **ArtifactRegistry.sol (H-02)**:
   - Added `gameContract` state variable
   - Added `onlyGame` modifier
   - `claimArtifactProcedural` now protected by `onlyGame`
   - Added `setGameContract()` for initialization
   - Prevents unauthorized artifact claims

---
*Auto-generated tracker for overnight security fix session*
