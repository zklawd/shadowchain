# ShadowChain E2E Tests

Comprehensive end-to-end ZK proof tests using [hardhat-noir](https://github.com/olehmisar/hardhat-noir).

## Why E2E Testing?

**Test locally before deploying to networks!**

- Instant feedback (no block times)
- No gas costs
- Catch version mismatches early
- Debug proof generation issues locally

## Setup

```bash
npm install
npm run compile
```

## Run Tests

```bash
npm test                    # Run all tests
npm test -- --grep "fuzz"   # Run only fuzz tests
npm test -- --grep "ValidMove"  # Run specific circuit tests
```

## Test Structure

```
test/
├── fixtures/
│   └── GameFixture.ts      # Shared helpers, hash functions, circuit loaders
├── circuits/
│   ├── PositionCommit.test.ts   # Position commitment proofs
│   ├── ValidMove.test.ts        # Move validation proofs
│   ├── ClaimArtifact.test.ts    # Artifact claiming proofs
│   └── CombatReveal.test.ts     # Combat stats reveal proofs
└── fuzz/
    ├── StatsFuzz.test.ts        # Random artifact combinations
    └── MoveFuzz.test.ts         # Random move sequences
```

## What's Tested

### Circuit Tests

| Circuit | Tests | Description |
|---------|-------|-------------|
| `position_commit` | 6 | Valid/invalid commitment proofs |
| `valid_move` | 13 | All directions, walls, on-chain verification |
| `claim_artifact` | 8 | Artifact claiming, boundary cases |
| `combat_reveal` | 14 | Stat computation, artifact stacking |

### Fuzz Tests

| Category | Tests | Description |
|----------|-------|-------------|
| Stats Invariants | 3 | HP >= 1, ATK >= 1, DEF >= 0 |
| Random Artifacts | 20 | Random combinations verified against circuit |
| Extreme Stats | 3 | Max HP, ATK, DEF loadouts |
| Move Invariants | 30 | All valid moves from key positions |
| Diagonal Rejection | 4 | No diagonal moves allowed |
| Random Sequences | 5 | Chains of random valid moves |
| Wall Blocking | 2 | Walls block destination, not origin |

## Fixtures

### GameFixture.ts

```typescript
// Hash helpers
computePositionCommitment(x, y, salt)
computeStatsCommitment(hp, atk, def, playerSalt)
computeInventoryCommitment(artifactIds, inventorySalt)
computeCellHash(x, y)

// Circuit helpers
getCircuit(name)
generateProof(circuitName, inputs)
verifyProofJS(circuitName, proof, publicInputs)

// Stat computation (matches contract + circuit)
computeStats(artifactIds)
ARTIFACT_STATS[id]  // { hp, atk, def }
BASE_STATS          // { hp: 100, atk: 10, def: 5 }
```

## Key Learnings

### 1. Always use `{ keccak: true }`
```typescript
// WRONG - fails on-chain
backend.generateProof(witness);

// CORRECT - Solidity-compatible
backend.generateProof(witness, { keccak: true });
```

### 2. Version Matching
The Noir version in `hardhat.config.ts` MUST match your `@noir-lang/noir_js` and `@aztec/bb.js` versions.

Current working combo:
- Noir: 1.0.0-beta.3
- noir_js: 1.0.0-beta.3
- bb.js: 0.82.2

### 3. Pedersen Hash for Commitments
Use `Barretenberg.pedersenHash()` to compute commitments that match Noir's `std::hash::pedersen_hash`.

### 4. Stack Depth for Verifiers
If you get "stack too deep" errors compiling verifiers, set `viaIR: false` in hardhat config.

## Adding New Tests

1. Add circuit test in `test/circuits/<Circuit>.test.ts`
2. Use fixtures from `GameFixture.ts`
3. Add fuzz tests in `test/fuzz/` for invariant checking
4. Keep proof generation tests separate from on-chain verification

---

*Part of [ShadowChain](https://github.com/zklawd/shadowchain) - ZK fog-of-war arena game*
