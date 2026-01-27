# ShadowChain: ZK Fog-of-War Arena

## Concept

A multiplayer on-chain strategy game where players navigate a hidden dungeon grid, collect artifacts, and battle each other — all with private state verified by zero-knowledge proofs.

**Why ZK?** Every player's position, inventory, and stats are hidden. You don't know where anyone is until you collide. ZK proofs ensure nobody cheats — valid moves, honest combat, real loot — without revealing private information.

**Tagline:** *"Move in shadow. Strike with proof."*

---

## Game Overview

### Core Loop
1. **Join** — Player stakes entry fee, commits to starting position
2. **Explore** — Move through a grid dungeon, position stays hidden
3. **Collect** — Find artifacts that boost stats (hidden from others)
4. **Fight** — When two players occupy the same cell, combat triggers
5. **Survive** — Last player standing (or highest score when timer ends) wins the pot

### Map
- 16x16 grid dungeon (256 cells)
- Map is public (walls, treasure rooms, traps are known)
- Player positions are private (committed via hash, proven via ZK)
- Map is generated deterministically from a seed (blockhash at game creation)

### Players
- 2-8 players per match
- Each player has hidden stats: HP (100), Attack (10), Defense (5)
- Stats modified by collected artifacts (ZK-proven)
- Players commit moves each turn (or auto-skip after timeout)

### Turns
- Turn-based with a 60-second timer per turn
- Each turn: commit a move (direction: N/S/E/W/stay) + action (explore/attack)
- Move is validated by ZK proof: "I moved from a valid position to an adjacent valid cell"
- All moves revealed simultaneously at turn end

### Combat
- Triggered when two players prove they occupy the same cell
- Attacker submits combat proof: proves their stats + attack action
- Defender's stats are revealed for that combat only
- Damage = max(0, attacker_attack - defender_defense) + random_modifier
- Random modifier derived from blockhash + player secrets (verifiable)

### Artifacts
- Placed at known "treasure cells" on the map
- First player to prove they're on a treasure cell claims it
- Artifact effects: +5 attack, +5 defense, +20 HP, etc.
- Claiming is ZK-proven: "I am at cell (x,y) which is a treasure cell"

### Win Conditions
- **Elimination:** Last player standing wins 100% of pot
- **Timer:** After 50 turns, highest HP + artifact score wins
- **Forfeit:** Players can exit early (lose stake, reduce pot)

---

## Architecture

### Layer 1: Noir Circuits (ZK Proofs)

#### Circuit 1: `position_commit`
- **Private inputs:** x, y, salt
- **Public inputs:** commitment (hash)
- **Proves:** commitment = hash(x, y, salt)

#### Circuit 2: `valid_move`
- **Private inputs:** old_x, old_y, old_salt, new_x, new_y, new_salt, direction
- **Public inputs:** old_commitment, new_commitment, map_root
- **Proves:**
  - old_commitment = hash(old_x, old_y, old_salt)
  - new_commitment = hash(new_x, new_y, new_salt)
  - (new_x, new_y) is adjacent to (old_x, old_y) in the given direction
  - (new_x, new_y) is not a wall (verified against map_root)
  - Coordinates are within bounds (0-15)

#### Circuit 3: `claim_artifact`
- **Private inputs:** x, y, salt
- **Public inputs:** commitment, artifact_cell_hash, artifact_id
- **Proves:**
  - commitment = hash(x, y, salt)
  - hash(x, y) = artifact_cell_hash (player is at the treasure cell)

#### Circuit 4: `combat_reveal`
- **Private inputs:** x, y, salt, hp, attack, defense, artifact_ids[], artifact_salts[]
- **Public inputs:** commitment, stats_commitment, game_id
- **Proves:**
  - commitment = hash(x, y, salt)
  - Stats are correctly derived from base stats + artifacts
  - stats_commitment = hash(hp, attack, defense, player_salt)

#### Circuit 5: `encounter_check`
- **Private inputs:** my_x, my_y, my_salt, their_commitment
- **Public inputs:** my_commitment, encounter_proof (boolean)
- **Proves:**
  - If encounter_proof = true: both players are at the same cell
  - Does NOT reveal the cell coordinates

### Layer 2: Solidity Smart Contracts

#### `ShadowChainGame.sol` — Main Game Contract
- Game lifecycle: create → join → play → resolve
- Turn management with commit-reveal scheme
- Player registration + stake handling
- References verifier contracts for proof validation

#### `MapGenerator.sol` — Deterministic Map
- Generates 16x16 grid from seed
- Marks walls, treasure cells, spawn points
- Pure function: `getMap(seed) → uint256[8]` (bitmap)

#### `ShadowVerifier.sol` — Noir Proof Verifiers
- Auto-generated from Noir circuits via `nargo codegen-verifier`
- One verifier per circuit (or unified UltraPlonk verifier)

#### `ArtifactRegistry.sol` — Artifact Definitions
- Maps artifact IDs to stat modifications
- Tracks claimed artifacts per game

#### `Treasury.sol` — Stake + Reward Management
- Entry fee collection
- Winner payout
- Protocol fee (optional)

### Layer 3: Frontend (React + Next.js)

#### Game Client
- Connect wallet (wagmi/viem)
- Game lobby: create/join matches
- Game board: 16x16 grid visualization
- Your position shown (private), fog of war for others
- Turn submission with proof generation (Noir WASM in browser)
- Combat resolution UI
- Real-time game state via events

#### Proof Generation
- Noir compiled to WASM for in-browser proving
- ~2-5 second proof time target
- Fallback: server-side proving relay

---

## Tech Stack

| Layer | Tech |
|-------|------|
| ZK Circuits | Noir (Aztec) |
| Smart Contracts | Solidity + Foundry |
| Proof System | UltraHonk (via Noir/bb) |
| Frontend | Next.js + React + TypeScript |
| Wallet | wagmi + viem + RainbowKit |
| Chain | Ethereum Sepolia (testnet) → Mainnet |
| Proof in Browser | @noir-lang/noir_js + @noir-lang/backend_barretenberg |
| Styling | Tailwind CSS |
| Game Art | Pixel art / ASCII aesthetic |

---

## Development Phases

### Phase 1: Core Circuits ✍️
- [ ] position_commit circuit
- [ ] valid_move circuit
- [ ] claim_artifact circuit
- [ ] All circuits compile and pass tests

### Phase 2: Smart Contracts 📜
- [ ] MapGenerator with deterministic generation
- [ ] ShadowChainGame with turn management
- [ ] Integration with Noir verifiers
- [ ] Full Foundry test suite

### Phase 3: Frontend 🖥️
- [ ] Game lobby (create/join)
- [ ] Board renderer with fog of war
- [ ] In-browser proof generation
- [ ] Turn submission flow
- [ ] Combat resolution UI

### Phase 4: Integration + Deploy 🚀
- [ ] End-to-end test on local anvil
- [ ] Deploy to Sepolia
- [ ] Frontend deployment
- [ ] Playtesting

---

## File Structure

```
shadowchain/
├── DESIGN.md              # This file
├── circuits/              # Noir circuits
│   ├── position_commit/
│   ├── valid_move/
│   ├── claim_artifact/
│   └── combat_reveal/
├── contracts/             # Solidity (Foundry)
│   ├── src/
│   │   ├── ShadowChainGame.sol
│   │   ├── MapGenerator.sol
│   │   ├── ArtifactRegistry.sol
│   │   └── verifiers/
│   ├── test/
│   └── foundry.toml
├── frontend/              # Next.js app
│   ├── src/
│   ├── public/
│   └── package.json
└── README.md
```

---

*Move in shadow. Strike with proof.* 🛡️
