export type CellType = 'empty' | 'wall' | 'treasure' | 'spawn' | 'trap';

export interface Position {
  x: number;
  y: number;
}

export interface Cell {
  type: CellType;
  x: number;
  y: number;
}

export interface Artifact {
  id: string;
  name: string;
  effect: string;
  statBoost: {
    hp?: number;
    attack?: number;
    defense?: number;
  };
}

export interface Player {
  address: string;
  hp: number;
  maxHp: number;
  attack: number;
  defense: number;
  artifacts: Artifact[];
  isAlive: boolean;
  position?: Position;
  score: number;
}

export interface CombatEvent {
  id: string;
  timestamp: number;
  type: 'move' | 'combat' | 'artifact' | 'system' | 'death' | 'explore';
  message: string;
  players?: string[];
}

export interface GameState {
  id: string;
  turn: number;
  maxTurns: number;
  timeRemaining: number;
  phase: 'waiting' | 'active' | 'ended';
  players: Player[];
  map: Cell[][];
  currentPlayer: string;
  events: CombatEvent[];
  winner?: string;
  pot: string;
  entryFee: string;
  maxPlayers: number;
}

export interface LobbyGame {
  id: string;
  creator: string;
  entryFee: string;
  maxPlayers: number;
  currentPlayers: number;
  status: 'waiting' | 'active' | 'ended';
  createdAt: number;
}

export type Direction = 'N' | 'S' | 'E' | 'W' | 'stay';
export type GameAction = 'explore' | 'claim_artifact' | 'attack';
