# Security Fix Tracker

**Started:** 2026-01-29 ~07:00 UTC
**Status:** IN PROGRESS

## Critical Issues

| ID | Issue | Branch | Status | Notes |
|----|-------|--------|--------|-------|
| C-01 | claim_artifact missing treasure validation | `fix/c01-treasure-validation` | ⏳ PENDING | |
| C-02 | Circuit/contract nullifier mismatch | `fix/c02-nullifier` | ⏳ PENDING | |
| C-03 | combat_reveal no co-location proof | `fix/c03-combat-colocation` | ⏳ PENDING | |

## High Issues

| ID | Issue | Branch | Status | Notes |
|----|-------|--------|--------|-------|
| H-01 | submitMove no public input validation | `fix/h01-move-validation` | ⏳ PENDING | |
| H-02 | ArtifactRegistry no access control | `fix/h02-registry-access` | ⏳ PENDING | |
| H-03 | No game_id in move proofs | `fix/h03-game-binding` | ⏳ PENDING | |
| H-04 | combat_reveal allows duplicate artifacts | `fix/h04-artifact-uniqueness` | ⏳ PENDING | |

## Medium Issues

| ID | Issue | Branch | Status | Notes |
|----|-------|--------|--------|-------|
| M-01 | Treasure location front-running | `fix/m01-commit-reveal` | ⏳ PENDING | |
| M-02 | Weak combat randomness | `fix/m02-randomness` | ⏳ PENDING | |
| M-03 | position_commit no bounds | `fix/m03-position-bounds` | ⏳ PENDING | |
| M-04 | Prize griefing | `fix/m04-pull-payment` | ⏳ PENDING | |
| M-05 | setMapHash no access control | `fix/m05-maphash-access` | ⏳ PENDING | |

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

(Updates will be added here as fixes are completed)

---
*Auto-generated tracker for overnight security fix session*
