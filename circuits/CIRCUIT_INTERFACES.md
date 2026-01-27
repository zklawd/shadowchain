# ShadowChain Circuit Interfaces

All circuits use **Pedersen hash** (`std::hash::pedersen_hash`) and target **UltraHonk** proof system.

Nargo version: 1.0.0-beta.18 | bb version: 0.82.0

---

## 1. position_commit

**Purpose:** Prove knowledge of a position that hashes to a public commitment.

| Input Type | Name | Type |
|-----------|------|------|
| Private | x | Field |
| Private | y | Field |
| Private | salt | Field |
| **Public** | **commitment** | Field |

**Constraint:** `commitment == pedersen_hash([x, y, salt])`

---

## 2. valid_move

**Purpose:** Prove a move from old position to new position is valid (adjacent, in-bounds, not a wall).

| Input Type | Name | Type |
|-----------|------|------|
| Private | old_x | Field |
| Private | old_y | Field |
| Private | old_salt | Field |
| Private | new_x | Field |
| Private | new_y | Field |
| Private | new_salt | Field |
| **Public** | **old_commitment** | Field |
| **Public** | **new_commitment** | Field |
| **Public** | **map_walls** | Field[16] |

**Constraints:**
- `old_commitment == pedersen_hash([old_x, old_y, old_salt])`
- `new_commitment == pedersen_hash([new_x, new_y, new_salt])`
- Manhattan distance between old and new position <= 1
- Both positions in [0, 15] range
- New position is not a wall (checked against `map_walls` bitmap)

**Note:** `map_walls` is an array of 16 Fields, one per row. Each Field is treated as a bitmask where bit `col` set to 1 means wall at `(col, row)`.

---

## 3. claim_artifact

**Purpose:** Prove a player is at a treasure cell without revealing their position.

| Input Type | Name | Type |
|-----------|------|------|
| Private | x | Field |
| Private | y | Field |
| Private | salt | Field |
| **Public** | **commitment** | Field |
| **Public** | **artifact_cell_hash** | Field |
| **Public** | **artifact_id** | Field |

**Constraints:**
- `commitment == pedersen_hash([x, y, salt])`
- `artifact_cell_hash == pedersen_hash([x, y])` (cell hash without salt, so contracts can compute it for known treasure locations)
- `artifact_id != 0`

---

## 4. combat_reveal

**Purpose:** Prove stats are correctly derived from base stats + collected artifacts.

| Input Type | Name | Type |
|-----------|------|------|
| Private | x | Field |
| Private | y | Field |
| Private | salt | Field |
| Private | player_salt | Field |
| Private | artifact_ids | u32[4] |
| **Public** | **commitment** | Field |
| **Public** | **stats_commitment** | Field |
| **Public** | **game_id** | Field |

**Constraints:**
- `commitment == pedersen_hash([x, y, salt])`
- Stats computed from base (HP=100, ATK=10, DEF=5) + artifact bonuses
- `stats_commitment == pedersen_hash([hp as Field, attack as Field, defense as Field, player_salt])`
- `game_id != 0`

**Artifact Bonuses:**
| ID | Name | HP | ATK | DEF |
|----|------|-----|-----|-----|
| 0 | (empty) | +0 | +0 | +0 |
| 1 | HP Potion | +20 | +0 | +0 |
| 2 | Sharp Blade | +0 | +5 | +0 |
| 3 | Iron Shield | +0 | +0 | +5 |
| 4 | War Relic | +10 | +3 | +3 |

---

## Verifier Integration Notes

For Solidity verifier generation with UltraHonk:
```bash
bb write_vk -s ultra_honk -b target/<circuit>.json -o target/vk
bb write_solidity_verifier -k target/vk -o ../contracts/src/verifiers/<Circuit>Verifier.sol
```

Each verifier's `verify()` function takes the proof bytes and the public inputs listed above.
