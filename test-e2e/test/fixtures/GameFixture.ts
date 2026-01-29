import hre, { ethers } from "hardhat";

// ============================================================================
// Types
// ============================================================================

export interface PlayerState {
  address: string;
  x: bigint;
  y: bigint;
  salt: bigint;
  commitment: string;
  inventorySalt: bigint;
  inventoryCommitment: string;
  artifacts: number[]; // artifact IDs (0 = empty slot)
}

export interface GameState {
  gameId: bigint;
  seed: bigint;
  treasureSeed: string;
  wallBitmap: bigint;
  players: PlayerState[];
}

// ============================================================================
// Barretenberg Singleton
// ============================================================================

let _bb: any = null;
let _Fr: any = null;

export async function initBarretenberg() {
  if (_bb) return { bb: _bb, Fr: _Fr };
  
  const { Barretenberg, Fr } = await import("@aztec/bb.js");
  _bb = await Barretenberg.new();
  _Fr = Fr;
  
  return { bb: _bb, Fr: _Fr };
}

export async function destroyBarretenberg() {
  if (_bb) {
    await _bb.destroy();
    _bb = null;
    _Fr = null;
  }
}

// ============================================================================
// Hash Helpers
// ============================================================================

export async function computePedersenHash(inputs: bigint[]): Promise<string> {
  const { bb, Fr } = await initBarretenberg();
  
  const frInputs = inputs.map((n) => {
    const hex = n.toString(16).padStart(64, "0");
    return Fr.fromBuffer(Buffer.from(hex, "hex"));
  });
  
  const result = await bb.pedersenHash(frInputs, 0);
  return "0x" + Buffer.from(result.toBuffer()).toString("hex");
}

export async function computePositionCommitment(
  x: bigint,
  y: bigint,
  salt: bigint
): Promise<string> {
  return computePedersenHash([x, y, salt]);
}

export async function computeStatsCommitment(
  hp: bigint,
  attack: bigint,
  defense: bigint,
  playerSalt: bigint
): Promise<string> {
  return computePedersenHash([hp, attack, defense, playerSalt]);
}

export async function computeInventoryCommitment(
  artifactIds: number[],
  inventorySalt: bigint
): Promise<string> {
  // Pad to 8 slots
  const padded = [...artifactIds, ...Array(8 - artifactIds.length).fill(0)].slice(0, 8);
  return computePedersenHash([...padded.map(BigInt), inventorySalt]);
}

export async function computeCellHash(x: bigint, y: bigint): Promise<string> {
  return computePedersenHash([x, y]);
}

// ============================================================================
// Circuit Helpers
// ============================================================================

export interface CircuitContext {
  noir: any;
  backend: any;
}

const _circuits: Map<string, CircuitContext> = new Map();

export async function getCircuit(name: string): Promise<CircuitContext> {
  if (_circuits.has(name)) {
    return _circuits.get(name)!;
  }
  
  const { noir, backend } = await hre.noir.getCircuit(name);
  _circuits.set(name, { noir, backend });
  return { noir, backend };
}

export async function generateProof(
  circuitName: string,
  inputs: Record<string, any>
): Promise<{ proof: Uint8Array; publicInputs: string[] }> {
  const { noir, backend } = await getCircuit(circuitName);
  const { witness } = await noir.execute(inputs);
  const { proof, publicInputs } = await backend.generateProof(witness, {
    keccak: true,
  });
  return { proof, publicInputs };
}

export async function verifyProofJS(
  circuitName: string,
  proof: Uint8Array,
  publicInputs: string[]
): Promise<boolean> {
  const { backend } = await getCircuit(circuitName);
  return backend.verifyProof({ proof, publicInputs }, { keccak: true });
}

// ============================================================================
// Player Factory
// ============================================================================

export async function createPlayer(
  signer: any,
  x: bigint,
  y: bigint
): Promise<PlayerState> {
  const salt = BigInt(Math.floor(Math.random() * 1000000));
  const inventorySalt = BigInt(Math.floor(Math.random() * 1000000));
  
  const commitment = await computePositionCommitment(x, y, salt);
  const inventoryCommitment = await computeInventoryCommitment([], inventorySalt);
  
  return {
    address: await signer.getAddress(),
    x,
    y,
    salt,
    commitment,
    inventorySalt,
    inventoryCommitment,
    artifacts: [0, 0, 0, 0, 0, 0, 0, 0],
  };
}

// ============================================================================
// Wall Map Helpers
// ============================================================================

export function emptyWalls(): string[] {
  return Array(16).fill("0");
}

export function wallsToArray(wallBitmap: bigint): string[] {
  const walls: string[] = [];
  for (let row = 0; row < 16; row++) {
    // Extract 16 bits for this row
    const rowBits = (wallBitmap >> BigInt(row * 16)) & BigInt(0xFFFF);
    walls.push(rowBits.toString());
  }
  return walls;
}

// ============================================================================
// Artifact Stat Helpers (must match contract + circuit)
// ============================================================================

export const ARTIFACT_STATS: Record<number, { hp: number; atk: number; def: number }> = {
  0: { hp: 0, atk: 0, def: 0 },       // Empty
  1: { hp: 0, atk: 5, def: 0 },       // Shadow Blade
  2: { hp: 0, atk: 0, def: 5 },       // Iron Aegis
  3: { hp: 20, atk: 0, def: 0 },      // Vitality Amulet
  4: { hp: 0, atk: 8, def: -2 },      // Berserker Helm
  5: { hp: 10, atk: -1, def: 7 },     // Phantom Cloak
  6: { hp: 0, atk: 3, def: 3 },       // War Gauntlets
  7: { hp: -10, atk: 6, def: 0 },     // Blood Crystal
  8: { hp: 15, atk: 2, def: 2 },      // Soul Vessel
};

export const BASE_STATS = { hp: 100, atk: 10, def: 5 };

export function computeStats(artifactIds: number[]): { hp: number; atk: number; def: number } {
  let hp = BASE_STATS.hp;
  let atk = BASE_STATS.atk;
  let def = BASE_STATS.def;
  
  for (const id of artifactIds) {
    const stats = ARTIFACT_STATS[id] || { hp: 0, atk: 0, def: 0 };
    hp += stats.hp;
    atk += stats.atk;
    def += stats.def;
  }
  
  // Floor values (match contract)
  hp = Math.max(1, hp);
  atk = Math.max(1, atk);
  def = Math.max(0, def);
  
  return { hp, atk, def };
}
