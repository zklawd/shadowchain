# ShadowChain Circuit Interfaces

This document defines the public interfaces for all ZK circuits in ShadowChain.
**Version:** 2.0 (Security-hardened)
**Last Updated:** 2026-01-29

## Overview

All circuits use Pedersen hash for commitments (compatible with on-chain verification).
The `claim_artifact` circuit uses Poseidon for procedural treasure generation.

---

## 1. position_commit

**Purpose:** Prove knowledge of a valid position without revealing it.

### Inputs

| Name | Type | Visibility | Description |
|------|------|------------|-------------|
| x | Field | Private | X coordinate (0-15) |
| y | Field | Private | Y coordinate (0-15) |
| salt | Field | Private | Random salt |
| commitment | Field | **Public** | Position commitment |

### Verification
- `x < 16 && y < 16` (bounds check)
- `commitment == pedersen_hash([x, y, salt])`

---

## 2. valid_move

**Purpose:** Prove a move from old position to new position is valid.

### Inputs

| Name | Type | Visibility | Description |
|------|------|------------|-------------|
| old_x | Field | Private | Old X coordinate |
| old_y | Field | Private | Old Y coordinate |
| old_salt | Field | Private | Old position salt |
| new_x | Field | Private | New X coordinate |
| new_y | Field | Private | New Y coordinate |
| new_salt | Field | Private | New position salt |
| map_walls | [Field; 16] | Private | Wall bitmap per row |
| old_commitment | Field | **Public** | Old position commitment |
| new_commitment | Field | **Public** | New position commitment |
| map_hash | Field | **Public** | Hash of map_walls |

### Verification
- Both positions in bounds (0-15)
- Both commitments are correct
- Move is adjacent (N/S/E/W) or stay in place
- Neither position is a wall

---

## 3. claim_artifact (SECURED)

**Purpose:** Prove player is at a treasure cell and compute nullifier.

### Inputs

| Name | Type | Visibility | Description |
|------|------|------------|-------------|
| x | Field | Private | X coordinate (0-15) |
| y | Field | Private | Y coordinate (0-15) |
| salt | Field | Private | Position salt |
| player_secret | Field | Private | Player's secret for nullifier |
| commitment | Field | **Public** | Position commitment |
| treasure_seed | Field | **Public** | Game's treasure seed |
| artifact_id | Field | **Public** | Derived artifact ID (1-8) |
| nullifier | Field | **Public** | Prevents double-claiming |

### Verification
1. Position in bounds (0-15)
2. `commitment == pedersen_hash([x, y, salt])`
3. `poseidon(x, y, treasure_seed) % 256 < 20` (cell is treasure)
4. `artifact_id == (poseidon(x, y, treasure_seed, ARTIFACT_DOMAIN_SEP) % 8) + 1`
5. `nullifier == poseidon(player_secret, x, y, treasure_seed, NULLIFIER_DOMAIN_SEP)`

### Contract Integration
- **MUST** track used nullifiers in `mapping(uint256 => bool)`
- **MUST** reject proofs with already-used nullifiers
- Nullifier is unique per (player_secret, treasure_location) pair

---

## 4. combat_reveal (SECURED)

**Purpose:** Prove player stats based on owned artifacts.

### Inputs

| Name | Type | Visibility | Description |
|------|------|------------|-------------|
| x | Field | Private | X coordinate (0-15) |
| y | Field | Private | Y coordinate (0-15) |
| salt | Field | Private | Position salt |
| player_salt | Field | Private | Stats commitment salt |
| artifact_ids | [u32; 8] | Private | Artifacts used in combat |
| owned_artifacts | [u32; 8] | Private | Player's full inventory |
| inventory_salt | Field | Private | Inventory commitment salt |
| commitment | Field | **Public** | Position commitment |
| stats_commitment | Field | **Public** | Hash(hp, atk, def, player_salt) |
| game_id | Field | **Public** | Binds proof to specific game |
| inventory_commitment | Field | **Public** | Hash(owned_artifacts, inventory_salt) |

### Verification
1. `commitment == pedersen_hash([x, y, salt])`
2. Position in bounds (0-15)
3. `inventory_commitment` matches hash of `owned_artifacts`
4. All claimed artifacts exist in owned_artifacts
5. No duplicate non-zero artifacts in claimed set
6. Stats correctly computed from base + artifact bonuses
7. `stats_commitment` matches computed stats

### Contract Integration
- **MUST** track `inventory_commitment` per player (updated on artifact claim)
- **MUST** verify `game_id` matches current game
- Prevents claiming artifacts player doesn't own
- Prevents stacking same artifact multiple times

---

## Domain Separators

```solidity
// claim_artifact nullifier
bytes32 constant NULLIFIER_DOMAIN_SEP = 0x6e756c6c6966696572; // "nullifier" as ASCII

// claim_artifact artifact ID
bytes32 constant ARTIFACT_DOMAIN_SEP = 0x617274696661637400; // "artifact" as ASCII
```

---

## Base Stats

| Stat | Base Value | Floor |
|------|------------|-------|
| HP | 100 | 1 |
| Attack | 10 | 1 |
| Defense | 5 | 0 |

---

## Artifact Bonuses

| ID | Name | HP | ATK | DEF |
|----|------|-----|------|------|
| 1 | Shadow Blade | 0 | +5 | 0 |
| 2 | Iron Aegis | 0 | 0 | +5 |
| 3 | Vitality Amulet | +20 | 0 | 0 |
| 4 | Berserker Helm | 0 | +8 | -2 |
| 5 | Phantom Cloak | +10 | -1 | +7 |
| 6 | War Gauntlets | 0 | +3 | +3 |
| 7 | Blood Crystal | -10 | +6 | 0 |
| 8 | Soul Vessel | +15 | +2 | +2 |

---

## Migration Notes (v1 → v2)

### Breaking Changes

1. **claim_artifact**: New inputs `player_secret` and `nullifier`
   - Contract must add `mapping(uint256 => bool) usedNullifiers`
   - Verifier public inputs: `[commitment, treasure_seed, artifact_id, nullifier]`

2. **combat_reveal**: New inputs `owned_artifacts`, `inventory_salt`, `inventory_commitment`
   - Contract must track `mapping(address => uint256) inventoryCommitments`
   - Verifier public inputs: `[commitment, stats_commitment, game_id, inventory_commitment]`

### Regenerate Verifiers
After any circuit change, regenerate Solidity verifiers:
```bash
cd circuits/<name>
nargo compile
bb write_vk
bb contract
```
