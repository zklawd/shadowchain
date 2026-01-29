# ShadowChain E2E Tests

End-to-end ZK proof tests using [hardhat-noir](https://github.com/olehmisar/hardhat-noir).

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
npm test
```

## What's Tested

| Circuit | Test | Description |
|---------|------|-------------|
| `valid_move` | ✅ | Generate + verify move proof on-chain |
| `claim_artifact` | TODO | Artifact claiming with nullifier |
| `combat_reveal` | TODO | Combat with inventory commitment |
| `position_commit` | TODO | Simple position commitment |

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
Use `Barretenberg.pedersenHash()` to compute commitments that match Noir's `std::hash::pedersen_hash`:

```typescript
const { Barretenberg, Fr } = await import("@aztec/bb.js");
const bb = await Barretenberg.new();

const commitment = await bb.pedersenHash([
  Fr.fromBuffer(Buffer.from(x.toString(16).padStart(64, "0"), "hex")),
  Fr.fromBuffer(Buffer.from(y.toString(16).padStart(64, "0"), "hex")),
  Fr.fromBuffer(Buffer.from(salt.toString(16).padStart(64, "0"), "hex")),
], 0);
```

### 4. Stack Depth for Verifiers
If you get "stack too deep" errors compiling verifiers, disable `viaIR`:

```typescript
// hardhat.config.ts
solidity: {
  settings: {
    optimizer: { enabled: true, runs: 1 },
    viaIR: false,  // Disable for verifier contracts
  },
}
```

## Project Structure

```
test-e2e/
├── contracts/        # Test wrapper contracts
├── noir/            # Symlink to ../circuits
├── test/            # TypeScript tests
└── hardhat.config.ts
```

---

*Part of [ShadowChain](https://github.com/zklawd/shadowchain) - ZK fog-of-war arena game*
