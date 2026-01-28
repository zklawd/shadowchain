# Procedural Treasures Design

## Overview

Replace pre-determined `treasureBitmap` with procedurally generated treasures that nobody can predict until the game starts.

## Mechanism

```
┌─────────────────────────────────────────────────────────────────┐
│  GAME CREATION                                                  │
│    game_seed = blockhash (for walls only)                       │
│    treasureSeed = 0 (not set yet)                              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  PLAYERS JOIN                                                   │
│    Player 1: commitment_1 = hash(x1, y1, salt1)                │
│    Player 2: commitment_2 = hash(x2, y2, salt2)                │
│    ...                                                          │
│    commitments[] stored in order                                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  GAME STARTS (when full or manually triggered)                  │
│    treasureSeed = hash(game_seed, commit[0], commit[1], ...)   │
│    Now treasures are deterministic but unpredictable            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  TREASURE EXISTS AT (x, y) IF:                                  │
│    cell_hash = hash(x, y, treasureSeed)                        │
│    (cell_hash % 256) < TREASURE_THRESHOLD                       │
│                                                                 │
│    e.g., threshold = 20 → ~8% of cells have treasure           │
│          threshold = 10 → ~4% of cells (~10 treasures)         │
└─────────────────────────────────────────────────────────────────┘
```

## Security Properties

1. **Creator can't cheat:** Treasure locations depend on ALL player commitments
2. **No pre-computation:** Treasures only become deterministic after last player joins
3. **Verifiable:** Anyone can verify treasure locations from public `treasureSeed`
4. **ZK-compatible:** Circuit can prove "I'm at a valid treasure cell" without revealing position

## Contract Changes

### Game Struct
```solidity
struct Game {
    // ... existing fields ...
    // REMOVE: uint256 treasureBitmap;
    bytes32 treasureSeed;        // NEW: computed on game start
    bytes32[] commitments;       // NEW: store player commitments in order
}

// Constants
uint8 public constant TREASURE_THRESHOLD = 20; // ~8% density
```

### joinGame()
```solidity
function joinGame(uint256 gameId, bytes32 commitment, ...) {
    // ... existing logic ...
    
    // Store commitment for treasure seed computation
    g.commitments.push(commitment);
    
    if (g.playerCount == g.maxPlayers) {
        _startGame(gameId);
    }
}
```

### _startGame()
```solidity
function _startGame(uint256 gameId) internal {
    Game storage g = games[gameId];
    
    // Compute treasure seed from all commitments
    bytes32 seed = bytes32(g.seed);
    for (uint i = 0; i < g.commitments.length; i++) {
        seed = keccak256(abi.encodePacked(seed, g.commitments[i]));
    }
    g.treasureSeed = seed;
    
    g.state = GameState.Active;
    // ... rest of start logic ...
}
```

### claimArtifact() - New Verification
```solidity
function claimArtifact(
    uint256 gameId,
    uint8 cellX,
    uint8 cellY,
    bytes calldata proof,
    bytes32[] calldata publicInputs
) external {
    Game storage g = games[gameId];
    
    // Verify via ZK proof that:
    // 1. Player is at (cellX, cellY)
    // 2. hash(cellX, cellY, treasureSeed) % 256 < TREASURE_THRESHOLD
    require(artifactVerifier.verify(proof, publicInputs), "Invalid proof");
    
    // Derive artifact ID from cell (deterministic)
    uint8 artifactId = _getArtifactAtCell(cellX, cellY, g.treasureSeed);
    
    // ... rest of claim logic ...
}

function _getArtifactAtCell(uint8 x, uint8 y, bytes32 treasureSeed) internal pure returns (uint8) {
    bytes32 h = keccak256(abi.encodePacked(x, y, treasureSeed, "artifact"));
    return uint8(uint256(h) % 8) + 1; // Artifact IDs 1-8
}
```

## Circuit Changes (claim_artifact.nr)

```noir
// Constants
global TREASURE_THRESHOLD: u8 = 20;

fn main(
    // Private
    x: Field,
    y: Field,
    salt: Field,
    
    // Public
    commitment: pub Field,
    treasure_seed: pub Field,
    artifact_id: pub Field,
) {
    // 1. Verify position commitment
    let computed_commitment = pedersen_hash([x, y, salt]);
    assert(computed_commitment == commitment);
    
    // 2. Verify cell is a treasure (procedural check)
    let cell_hash = pedersen_hash([x, y, treasure_seed]);
    let cell_value = (cell_hash as u64) % 256;
    assert(cell_value < TREASURE_THRESHOLD as u64, "Not a treasure cell");
    
    // 3. Verify artifact ID matches (deterministic from cell)
    let artifact_hash = pedersen_hash([x, y, treasure_seed, 1]); // 1 = "artifact" domain separator
    let expected_artifact = (artifact_hash as u64) % 8 + 1;
    assert(artifact_id == expected_artifact as Field);
}
```

## Frontend Changes

### Treasure Discovery
```typescript
function isTreasureCell(x: number, y: number, treasureSeed: bigint): boolean {
  const cellHash = pedersenHash([BigInt(x), BigInt(y), treasureSeed]);
  return (cellHash % 256n) < TREASURE_THRESHOLD;
}

function getArtifactId(x: number, y: number, treasureSeed: bigint): number {
  const artifactHash = pedersenHash([BigInt(x), BigInt(y), treasureSeed, 1n]);
  return Number(artifactHash % 8n) + 1;
}

// In game page: compute visible treasures
const visibleTreasures = useMemo(() => {
  if (!treasureSeed || !playerPos) return [];
  
  const treasures = [];
  for (const cellKey of visibleCells) {
    const [x, y] = cellKey.split(',').map(Number);
    if (isTreasureCell(x, y, treasureSeed)) {
      treasures.push({ x, y, artifactId: getArtifactId(x, y, treasureSeed) });
    }
  }
  return treasures;
}, [treasureSeed, playerPos, visibleCells]);
```

## Migration Path

1. Deploy new contract version with `treasureSeed` support
2. Update `claim_artifact` circuit with procedural check
3. Update frontend to compute treasures from seed
4. Remove `treasureBitmap` from contract and frontend

## Testing

- Create game → treasureSeed should be 0
- Join with player 1 → still 0
- Join with player 2 (game full) → treasureSeed computed
- Verify treasure locations match between contract helper and frontend
- Claim artifact at computed treasure cell → should succeed
- Claim artifact at non-treasure cell → should fail proof

## Gas Considerations

- Storing commitments array adds ~20k gas per player
- Computing treasureSeed on start adds ~5k gas per player (keccak loop)
- Total: ~25k extra gas per player (acceptable for 2-8 players)
