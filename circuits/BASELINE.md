# Circuit Baseline Benchmarks

*Captured: 2026-01-29 before optimization*

## ACIR Opcodes (main functions)

| Circuit | ACIR Opcodes | Brillig Opcodes | Notes |
|---------|-------------|-----------------|-------|
| position_commit | 8 | 36 | Very small, likely minimal |
| valid_move | 189 | 70 | Moderate |
| claim_artifact | **1695** | 70 | Largest - priority target |
| combat_reveal | 714 | 53 | Medium |

## Optimization Targets

1. **claim_artifact** (1695 opcodes) — Most room for improvement
2. **combat_reveal** (714 opcodes) — Medium priority
3. **valid_move** (189 opcodes) — Lower priority
4. **position_commit** (8 opcodes) — Already minimal

## Known Issues

- `claim_artifact`: Warning about unused function `get_artifact_id`
