import { Cell, CellType, CombatEvent, GameState, LobbyGame, Player } from '@/types/game';

// Generate a deterministic 16x16 map
function generateMap(): Cell[][] {
  const map: Cell[][] = [];
  
  // Wall pattern - creates corridors and rooms
  const wallPositions = new Set([
    '2,0', '2,1', '2,2', '2,3', '2,5', '2,6',
    '5,2', '5,3', '5,4', '5,5', '5,6', '5,7', '5,8',
    '8,0', '8,1', '8,2', '8,4', '8,5', '8,6', '8,8', '8,9',
    '10,3', '10,4', '10,5', '10,7', '10,8', '10,9', '10,10',
    '13,1', '13,2', '13,3', '13,5', '13,6', '13,7', '13,8', '13,9',
    '0,5', '1,5', '3,10', '4,10', '6,13', '7,13',
    '0,12', '1,12', '2,12', '3,12',
    '9,11', '9,12', '9,13', '9,14',
    '12,11', '12,12', '12,13',
    '14,5', '14,6', '15,5',
    '6,3', '7,3',
    '11,14', '11,15', '12,15',
    '3,7', '4,7',
    '7,10', '7,11',
    '15,10', '15,11', '15,12',
  ]);

  const treasurePositions = new Set([
    '4,4', '11,2', '7,8', '14,13', '1,14', '12,6', '3,11', '9,15',
  ]);

  const spawnPositions = new Set([
    '0,0', '15,0', '0,15', '15,15',
    '7,0', '0,7', '15,7', '7,15',
  ]);

  for (let y = 0; y < 16; y++) {
    const row: Cell[] = [];
    for (let x = 0; x < 16; x++) {
      const key = `${x},${y}`;
      let type: CellType = 'empty';
      if (wallPositions.has(key)) type = 'wall';
      else if (treasurePositions.has(key)) type = 'treasure';
      else if (spawnPositions.has(key)) type = 'spawn';
      row.push({ type, x, y });
    }
    map.push(row);
  }
  return map;
}

const mockPlayers: Player[] = [
  {
    address: '0x1234567890abcdef1234567890abcdef12345678',
    hp: 100,
    maxHp: 100,
    attack: 15,
    defense: 8,
    artifacts: [
      { id: '1', name: 'Shadow Blade', effect: '+5 ATK', statBoost: { attack: 5 } },
    ],
    isAlive: true,
    position: { x: 6, y: 6 }, // Player's own position
    score: 150,
  },
  {
    address: '0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
    hp: 75,
    maxHp: 100,
    attack: 12,
    defense: 5,
    artifacts: [],
    isAlive: true,
    score: 80,
  },
  {
    address: '0xcafebabecafebabecafebabecafebabecafebabe',
    hp: 45,
    maxHp: 120,
    attack: 10,
    defense: 10,
    artifacts: [
      { id: '2', name: 'Ethereal Shield', effect: '+5 DEF', statBoost: { defense: 5 } },
    ],
    isAlive: true,
    score: 200,
  },
  {
    address: '0x1111111111111111111111111111111111111111',
    hp: 0,
    maxHp: 100,
    attack: 10,
    defense: 5,
    artifacts: [],
    isAlive: false,
    score: 30,
  },
];

const mockEvents: CombatEvent[] = [
  {
    id: '1',
    timestamp: Date.now() - 180000,
    type: 'system',
    message: 'Game #42 started — 4 shadows enter the arena',
  },
  {
    id: '2',
    timestamp: Date.now() - 150000,
    type: 'move',
    message: '0x1234...5678 moves through the darkness',
  },
  {
    id: '3',
    timestamp: Date.now() - 120000,
    type: 'artifact',
    message: '0x1234...5678 claims Shadow Blade (+5 ATK)',
    players: ['0x1234567890abcdef1234567890abcdef12345678'],
  },
  {
    id: '4',
    timestamp: Date.now() - 90000,
    type: 'explore',
    message: '0xcafe...babe explores a dimly lit corridor',
    players: ['0xcafebabecafebabecafebabecafebabecafebabe'],
  },
  {
    id: '5',
    timestamp: Date.now() - 60000,
    type: 'combat',
    message: '0xdead...beef encounters 0x1111...1111 — Combat initiated!',
    players: [
      '0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
      '0x1111111111111111111111111111111111111111',
    ],
  },
  {
    id: '6',
    timestamp: Date.now() - 55000,
    type: 'combat',
    message: '0xdead...beef strikes for 25 damage! ZK proof verified ✓',
    players: ['0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef'],
  },
  {
    id: '7',
    timestamp: Date.now() - 50000,
    type: 'death',
    message: '0x1111...1111 has been eliminated. Stake forfeited.',
    players: ['0x1111111111111111111111111111111111111111'],
  },
  {
    id: '8',
    timestamp: Date.now() - 30000,
    type: 'artifact',
    message: '0xcafe...babe claims Ethereal Shield (+5 DEF)',
    players: ['0xcafebabecafebabecafebabecafebabecafebabe'],
  },
  {
    id: '9',
    timestamp: Date.now() - 10000,
    type: 'system',
    message: 'Turn 12 begins — 38 turns remaining',
  },
];

export const mockGameState: GameState = {
  id: '42',
  turn: 12,
  maxTurns: 50,
  timeRemaining: 45,
  phase: 'active',
  players: mockPlayers,
  map: generateMap(),
  currentPlayer: '0x1234567890abcdef1234567890abcdef12345678',
  events: mockEvents,
  pot: '0.4',
  entryFee: '0.1',
  maxPlayers: 4,
};

export const mockLobbyGames: LobbyGame[] = [
  {
    id: '42',
    creator: '0x1234567890abcdef1234567890abcdef12345678',
    entryFee: '0.1',
    maxPlayers: 4,
    currentPlayers: 4,
    status: 'active',
    createdAt: Date.now() - 600000,
  },
  {
    id: '43',
    creator: '0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
    entryFee: '0.05',
    maxPlayers: 8,
    currentPlayers: 3,
    status: 'waiting',
    createdAt: Date.now() - 300000,
  },
  {
    id: '44',
    creator: '0xcafebabecafebabecafebabecafebabecafebabe',
    entryFee: '0.25',
    maxPlayers: 2,
    currentPlayers: 1,
    status: 'waiting',
    createdAt: Date.now() - 120000,
  },
  {
    id: '45',
    creator: '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd',
    entryFee: '0.5',
    maxPlayers: 4,
    currentPlayers: 2,
    status: 'waiting',
    createdAt: Date.now() - 60000,
  },
  {
    id: '41',
    creator: '0x9999999999999999999999999999999999999999',
    entryFee: '0.1',
    maxPlayers: 4,
    currentPlayers: 4,
    status: 'ended',
    createdAt: Date.now() - 3600000,
  },
];

// Helper to compute visible cells around the player (fog of war radius)
export function getVisibleCells(playerPos: { x: number; y: number }, radius: number = 3): Set<string> {
  const visible = new Set<string>();
  for (let dy = -radius; dy <= radius; dy++) {
    for (let dx = -radius; dx <= radius; dx++) {
      const nx = playerPos.x + dx;
      const ny = playerPos.y + dy;
      if (nx >= 0 && nx < 16 && ny >= 0 && ny < 16) {
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist <= radius) {
          visible.add(`${nx},${ny}`);
        }
      }
    }
  }
  return visible;
}

// Mock enemy positions (these would normally be hidden)
export const mockEnemyPositions: Record<string, { x: number; y: number }> = {
  '0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef': { x: 9, y: 5 },
  '0xcafebabecafebabecafebabecafebabecafebabe': { x: 3, y: 11 },
};
