# ShadowChain Deployments

## Sepolia Testnet (Chain ID: 11155111)

**Deployed:** 2026-01-28
**Deployer:** `0x1f8D11cc7792F0c7631974c19D9a21eD5aA50d97`

### Contracts

| Contract | Address | Tx Hash |
|----------|---------|---------|
| **ShadowChainGame (v3)** | `0x64261645b3BbBD637603B2E9cd4541F55e58BE79` | `0xd7987cd1267eb2408e33a79c81fa2f2d7c60cc5f9877490fb3c0659a3be196dc` |
| ShadowChainGame (v2 - deprecated) | `0x14858891533335c50825915b54932B8991Af011C` | `0xa9a7b636acd9ed7ebf1c1b01fd48eaf8075389107bb5dfe7d0d0f5cdecc19f91` |
| ShadowChainGame (v1 - deprecated) | `0x5fdD77012cc3A82Cc43Ebdc2258Cade1EeDcCD05` | `0x8be56fe494bb977cc3c52487b01adfd30aaa7fca65e549ae3b3145a017be1837` |
| ValidMoveHonkVerifier | `0x495A19Bc734dfAbA95EB29FAbd1f99400900D362` | `0xcaaee3c214cfadd7bfc3281ac1765f705c68c1e5691898d6aa7058f5f04b09f9` |
| ClaimArtifactHonkVerifier | `0x8218EBd4003B9F4A3FDFcE2694684494b0945166` | `0xa9111a98fc9fda8c2ca4f64ccf394c0321c6075f16c4e7621884f8586ec9255c` |
| CombatRevealHonkVerifier | `0x17F8e80a6E24b875ec83c239223eED5d853DB4EB` | `0xa2b31ddabb2ae10435ffbe15f833b5b37ca41121f1184050a775327aca594f65` |
| ArtifactRegistry | `0x8103b517515e07df74e0f02c76b04caeCA502290` | `0xc8d3b14ebf2dd78783112f9270638dc6862b343e2441237fa319030b45ac33de` |

### Explorer Links

- Game (v3 - Poseidon): https://sepolia.etherscan.io/address/0x64261645b3BbBD637603B2E9cd4541F55e58BE79
- Game (v2 - deprecated): https://sepolia.etherscan.io/address/0x14858891533335c50825915b54932B8991Af011C
- Game (v1 - deprecated): https://sepolia.etherscan.io/address/0x5fdD77012cc3A82Cc43Ebdc2258Cade1EeDcCD05
- Move Verifier: https://sepolia.etherscan.io/address/0x495A19Bc734dfAbA95EB29FAbd1f99400900D362
- Artifact Verifier: https://sepolia.etherscan.io/address/0x8218EBd4003B9F4A3FDFcE2694684494b0945166
- Combat Verifier: https://sepolia.etherscan.io/address/0x17F8e80a6E24b875ec83c239223eED5d853DB4EB
- Artifact Registry: https://sepolia.etherscan.io/address/0x8103b517515e07df74e0f02c76b04caeCA502290

### Noir Circuit Versions

- nargo: `1.0.0-beta.3`
- bb: `0.82.2`
- Proof system: UltraHonk (keccak oracle hash for Solidity)

### Notes

- Verifiers use real Noir-generated UltraHonk Solidity verifiers (not MockVerifier)
- `ShadowChainGame` constructor args: `(moveVerifier, artifactVerifier, combatVerifier, artifactRegistry)`
- Position commit verifier not deployed separately (used client-side only)

### Version History

**v3 (2026-01-28):** CRITICAL - Poseidon hash for circuit/contract consistency
- Contract and circuit now use identical Poseidon hashes
- `PoseidonT4.hash([x, y, treasureSeed])` for treasure check
- `PoseidonT5.hash([x, y, treasureSeed, ARTIFACT_DOMAIN_SEP])` for artifact ID
- Links pre-deployed PoseidonT4 (0x4443338E...) and PoseidonT5 (0x555333f3...)
- VERIFIED: Circuit and contract produce identical results for same inputs

**v2 (2026-01-28):** Procedural treasures via multi-party seed (BROKEN - used keccak256)
- `treasureSeed = hash(gameSeed, commit1, commit2, ...)` computed on game start
- Used keccak256 in contract but circuit used Pedersen - MISMATCH!

**v1 (2026-01-28):** Initial deployment with bitmap-based treasures
