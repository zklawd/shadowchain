# ShadowChain Debug Log

## 2026-01-29: ZK Proof Verification Failures

### Problem
ZK proofs generated in JS failed on-chain verification with various errors.

### Symptoms & Solutions

| Error | Selector | Cause | Fix |
|-------|----------|-------|-----|
| `ProofLengthWrong` | `0xed74ac0a` | Proof size mismatch (16256 vs 14080 bytes) | Use matching bb.js version with verifiers |
| `SumcheckFailed` | `0x9fc3a218` | Proof mathematically invalid for Solidity | Add `{ keccak: true }` to generateProof |
| `unreachable` (WASM) | N/A | Circuit/library version mismatch | Align nargo and noir_js versions |

### Root Cause
Version misalignment between:
- Circuit compiler (nargo)
- Verifier generator (bb CLI)
- JS proof library (bb.js)
- JS circuit executor (noir_js)

### Working Configuration
```
nargo:    1.0.0-beta.3
bb:       0.82.2
bb.js:    0.82.2
noir_js:  1.0.0-beta.3
```

### Critical Code Fix
```javascript
// ❌ WRONG - generates proof incompatible with Solidity verifier
const proof = await backend.generateProof(witness);

// ✅ CORRECT - keccak flag for Solidity-compatible proof hashing
const proof = await backend.generateProof(witness, { keccak: true });
```

### Pedersen Hash Verification
Verified that bb.js 0.82.2 `pedersenHash` matches Noir's `std::hash::pedersen_hash`:
- Input: x=5, y=5, salt=123
- Output: `0x0591f7c7f03dd4ecf33b51fee3df3c5b01065c06ea6fad422fc36d07f8fdfffc`
- Both produce identical results ✓

### bb.js API Differences

**bb.js 3.0.0 (newer):**
```javascript
const backend = new UltraHonkBackend(circuit.bytecode, bb);
bb.pedersenHash({ inputs: frInputs, hashIndex: 0 });
```

**bb.js 0.82.2 (working):**
```javascript
const backend = new UltraHonkBackend(circuit.bytecode);
const fr = Fr.fromBuffer(Buffer.from(hex, 'hex'));
bb.pedersenHash([fr1, fr2, fr3], 0);
```

### Verifier Compilation
- bb 3.0.0 verifiers hit "stack too deep" in Solidity even with `via_ir=true`
- bb 0.82.2 verifiers compile successfully
- Must rename library/contract names to avoid collisions when multiple verifiers in same project

### Lessons Learned
1. **Always check version alignment** - nargo, bb, bb.js, noir_js must be compatible
2. **Solidity needs keccak** - the `{ keccak: true }` flag is required for on-chain verification
3. **Proof size is a quick diagnostic** - 14080 bytes (440×32) vs 16256 bytes indicates version mismatch
4. **Test hash functions independently** - verify Pedersen/Poseidon outputs match between JS and circuit
5. **Keep backup verifiers** - when regenerating verifiers fails, use known-working ones
