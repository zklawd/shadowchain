/**
 * Browser-based ZK proof generation using Noir 1.0.0-beta.18 + Barretenberg.
 *
 * Supports all 4 ShadowChain circuits:
 *   - position_commit: prove commitment = hash(x, y, salt)
 *   - valid_move: prove adjacent move with correct commitments
 *   - claim_artifact: prove player is at a treasure cell
 *   - combat_reveal: prove stats derived from base + artifacts
 *
 * Each circuit gets its own Noir executor + UltraHonk backend instance,
 * sharing a single Barretenberg WASM instance.
 */

import type { Position } from '@/types/game';

// ── Types ────────────────────────────────────────────────

export interface MoveProofInputs {
  oldPos: Position;
  newPos: Position;
  oldSalt: bigint;
  newSalt: bigint;
  mapWalls: bigint[]; // 16 row bitmasks
}

export interface MoveProofResult {
  proof: Uint8Array;
  publicInputs: string[]; // hex-encoded field elements
  oldCommitment: string;
  newCommitment: string;
}

export interface PositionCommitInputs {
  x: number;
  y: number;
  salt: bigint;
}

export interface PositionCommitResult {
  proof: Uint8Array;
  publicInputs: string[];
  commitment: string;
}

export interface ClaimArtifactInputs {
  x: number;
  y: number;
  salt: bigint;
  playerSecret: bigint;   // NEW: for nullifier derivation
  treasureSeed: bigint;   // NEW: from contract
  artifactId: number;
}

export interface ClaimArtifactResult {
  proof: Uint8Array;
  publicInputs: string[];
  commitment: string;
  nullifier: string;      // NEW: for double-claim prevention
}

export interface CombatRevealInputs {
  x: number;
  y: number;
  salt: bigint;
  playerSalt: bigint;
  artifactIds: number[];      // Artifacts to use in combat (max 8)
  ownedArtifacts: number[];   // NEW: Full inventory (must match inventoryCommitment)
  inventorySalt: bigint;      // NEW: Salt for inventory commitment
  gameId: bigint;
}

export interface CombatRevealResult {
  proof: Uint8Array;
  publicInputs: string[];
  commitment: string;
  statsCommitment: string;
  inventoryCommitment: string; // NEW: for ownership verification
}

export interface InventoryCommitmentInputs {
  ownedArtifacts: number[];   // 8 artifact IDs (0 for empty slots)
  inventorySalt: bigint;
}

export interface InventoryCommitmentResult {
  commitment: string;
}

// ── Circuit names ────────────────────────────────────────

type CircuitName = 'position_commit' | 'valid_move' | 'claim_artifact' | 'combat_reveal';

// ── Base path for assets (GitHub Pages vs root) ─────

const BASE_PATH = process.env.NEXT_PUBLIC_BASE_PATH || '';

// ── Internal state ───────────────────────────────────────

let _wasmInitialized = false;
let _wasmInitPromise: Promise<void> | null = null;
let _bb: any = null; // Shared Barretenberg instance

interface CircuitState {
  noir: any;    // Noir executor
  backend: any; // UltraHonkBackend
}

const _circuits: Map<CircuitName, CircuitState> = new Map();
const _circuitLoadPromises: Map<CircuitName, Promise<CircuitState>> = new Map();

// ── WASM Initialization ─────────────────────────────────

async function _initWasm(): Promise<void> {
  if (_wasmInitialized) return;
  if (_wasmInitPromise) return _wasmInitPromise;

  _wasmInitPromise = (async () => {
    console.log('[ZK] Initializing WASM modules…');

    // Initialize ACVM and NoirC WASM from public/ folder
    const [{ default: initACVM }, { default: initNoirC }] = await Promise.all([
      import('@noir-lang/acvm_js'),
      import('@noir-lang/noirc_abi'),
    ]);

    await Promise.all([
      initACVM(fetch(`${BASE_PATH}/wasm/acvm_js_bg.wasm`)),
      initNoirC(fetch(`${BASE_PATH}/wasm/noirc_abi_wasm_bg.wasm`)),
    ]);

    console.log('[ZK] WASM modules initialized');
    _wasmInitialized = true;
  })();

  try {
    await _wasmInitPromise;
  } catch (err) {
    _wasmInitPromise = null; // allow retry
    throw err;
  }
}

// ── Barretenberg Singleton ──────────────────────────────

async function _getBB(): Promise<any> {
  if (_bb) return _bb;

  const { Barretenberg } = await import('@aztec/bb.js');
  _bb = await Barretenberg.new();
  console.log('[ZK] Barretenberg instance created');
  return _bb;
}

// ── Circuit Loading ─────────────────────────────────────

async function _loadCircuit(name: CircuitName): Promise<CircuitState> {
  if (_circuits.has(name)) return _circuits.get(name)!;
  if (_circuitLoadPromises.has(name)) return _circuitLoadPromises.get(name)!;

  const promise = (async () => {
    console.log(`[ZK] Loading circuit: ${name}`);

    // Ensure WASM is initialized first
    await _initWasm();

    // Load the compiled circuit artifact
    const res = await fetch(`${BASE_PATH}/circuits/${name}.json`);
    if (!res.ok) throw new Error(`Failed to load circuit ${name}: ${res.status}`);
    const circuit = await res.json();
    console.log(`[ZK] Circuit ${name} loaded (noir_version: ${circuit.noir_version})`);

    // Create Noir executor
    const { Noir } = await import('@noir-lang/noir_js');
    const noir = new Noir(circuit);

    // Create UltraHonk backend (shares the Barretenberg instance)
    const bb = await _getBB();
    const { UltraHonkBackend } = await import('@aztec/bb.js');
    const backend = new UltraHonkBackend(circuit.bytecode, bb);

    const state: CircuitState = { noir, backend };
    _circuits.set(name, state);
    _circuitLoadPromises.delete(name);
    console.log(`[ZK] Circuit ${name} ready`);
    return state;
  })();

  _circuitLoadPromises.set(name, promise);

  try {
    return await promise;
  } catch (err) {
    _circuitLoadPromises.delete(name);
    throw err;
  }
}

// ── Public Initialization API ───────────────────────────

/**
 * Pre-initialize the prover. Loads WASM + Barretenberg.
 * Optionally pre-loads specific circuits.
 */
export async function initProver(circuits?: CircuitName[]): Promise<void> {
  await _initWasm();
  await _getBB();

  if (circuits) {
    await Promise.all(circuits.map((c) => _loadCircuit(c)));
  }
}

/**
 * Check if the base WASM prover is ready.
 */
export function isProverReady(): boolean {
  return _wasmInitialized && _bb !== null;
}

/**
 * Check if a specific circuit is loaded.
 */
export function isCircuitReady(name: CircuitName): boolean {
  return _circuits.has(name);
}

// ── Position Commit Proof ───────────────────────────────

/**
 * Generate a ZK proof for position commitment.
 * Proves: commitment = hash(x, y, salt) without revealing x, y, salt.
 *
 * Used when joining a game.
 */
export async function generatePositionCommitProof(
  inputs: PositionCommitInputs
): Promise<PositionCommitResult> {
  const { noir, backend } = await _loadCircuit('position_commit');
  const { x, y, salt } = inputs;

  // Compute commitment
  const commitment = await computePedersenHash([
    BigInt(x),
    BigInt(y),
    salt,
  ]);

  const circuitInputs = {
    x: toFieldHex(BigInt(x)),
    y: toFieldHex(BigInt(y)),
    salt: toFieldHex(salt),
    commitment,
  };

  console.log('[ZK] Generating position_commit proof…', { x, y });

  const { witness } = await noir.execute(circuitInputs);
  const proof = await backend.generateProof(witness);

  console.log('[ZK] position_commit proof generated!', { proofBytes: proof.proof.length });

  return {
    proof: proof.proof,
    publicInputs: [commitment],
    commitment,
  };
}

// ── Valid Move Proof ────────────────────────────────────

/**
 * Generate a ZK proof for a valid move.
 *
 * Private inputs: old position + salt, new position + salt
 * Public inputs: old commitment, new commitment, map wall bitmasks
 */
export async function generateMoveProof(inputs: MoveProofInputs): Promise<MoveProofResult> {
  const { noir, backend } = await _loadCircuit('valid_move');
  const { oldPos, newPos, oldSalt, newSalt, mapWalls } = inputs;

  // Compute Pedersen commitments
  const oldCommitment = await computePedersenHash([
    BigInt(oldPos.x),
    BigInt(oldPos.y),
    oldSalt,
  ]);
  const newCommitment = await computePedersenHash([
    BigInt(newPos.x),
    BigInt(newPos.y),
    newSalt,
  ]);

  // Compute map hash (Pedersen hash of all 16 wall row bitmasks)
  const mapHash = await computePedersenHash(mapWalls);

  // Format map_walls as array of field strings (private input)
  const mapWallsArr = mapWalls.map((w) => toFieldHex(w));

  const circuitInputs = {
    old_x: toFieldHex(BigInt(oldPos.x)),
    old_y: toFieldHex(BigInt(oldPos.y)),
    old_salt: toFieldHex(oldSalt),
    new_x: toFieldHex(BigInt(newPos.x)),
    new_y: toFieldHex(BigInt(newPos.y)),
    new_salt: toFieldHex(newSalt),
    map_walls: mapWallsArr,
    old_commitment: oldCommitment,
    new_commitment: newCommitment,
    map_hash: mapHash,
  };

  console.log('[ZK] Generating valid_move proof...', {
    from: `(${oldPos.x}, ${oldPos.y})`,
    to: `(${newPos.x}, ${newPos.y})`,
    publicInputs: 3,
  });

  const { witness } = await noir.execute(circuitInputs);
  const proof = await backend.generateProof(witness);

  console.log('[ZK] valid_move proof generated!', { proofBytes: proof.proof.length });

  return {
    proof: proof.proof,
    publicInputs: [oldCommitment, newCommitment, mapHash],
    oldCommitment,
    newCommitment,
  };
}

// ── Claim Artifact Proof ────────────────────────────────

/**
 * Generate a ZK proof for claiming an artifact.
 * Proves the player is at a valid procedurally-generated treasure cell.
 * Includes nullifier to prevent double-claiming.
 *
 * Private inputs: x, y, salt, player_secret
 * Public inputs: commitment, treasure_seed, artifact_id, nullifier
 */
export async function generateClaimArtifactProof(
  inputs: ClaimArtifactInputs
): Promise<ClaimArtifactResult> {
  const { noir, backend } = await _loadCircuit('claim_artifact');
  const { x, y, salt, playerSecret, treasureSeed, artifactId } = inputs;

  // Compute position commitment = pedersen(x, y, salt)
  const commitment = await computePedersenHash([
    BigInt(x),
    BigInt(y),
    salt,
  ]);

  // Compute nullifier = poseidon(player_secret, x, y, treasure_seed, domain_sep)
  // Note: Using Pedersen here for simplicity - circuit uses Poseidon
  // This needs to match what the circuit computes!
  const NULLIFIER_DOMAIN_SEP = BigInt('0x6e756c6c6966696572'); // "nullifier" in ASCII
  const nullifier = await computePoseidonHash([
    playerSecret,
    BigInt(x),
    BigInt(y),
    treasureSeed,
    NULLIFIER_DOMAIN_SEP,
  ]);

  const circuitInputs = {
    x: toFieldHex(BigInt(x)),
    y: toFieldHex(BigInt(y)),
    salt: toFieldHex(salt),
    player_secret: toFieldHex(playerSecret),
    commitment,
    treasure_seed: toFieldHex(treasureSeed),
    artifact_id: toFieldHex(BigInt(artifactId)),
    nullifier,
  };

  console.log('[ZK] Generating claim_artifact proof…', { x, y, artifactId });

  const { witness } = await noir.execute(circuitInputs);
  const proof = await backend.generateProof(witness);

  console.log('[ZK] claim_artifact proof generated!', { proofBytes: proof.proof.length });

  return {
    proof: proof.proof,
    publicInputs: [commitment, toFieldHex(treasureSeed), toFieldHex(BigInt(artifactId)), nullifier],
    commitment,
    nullifier,
  };
}

// ── Combat Reveal Proof ─────────────────────────────────

// Artifact stat bonuses matching the circuit's lookup tables
const ARTIFACT_STATS: Record<number, { hp: number; atk: number; def: number; hpPen: number; atkPen: number; defPen: number }> = {
  0: { hp: 0, atk: 0, def: 0, hpPen: 0, atkPen: 0, defPen: 0 },       // Empty
  1: { hp: 0, atk: 5, def: 0, hpPen: 0, atkPen: 0, defPen: 0 },       // Shadow Blade
  2: { hp: 0, atk: 0, def: 5, hpPen: 0, atkPen: 0, defPen: 0 },       // Iron Aegis
  3: { hp: 20, atk: 0, def: 0, hpPen: 0, atkPen: 0, defPen: 0 },      // Vitality Amulet
  4: { hp: 0, atk: 8, def: 0, hpPen: 0, atkPen: 0, defPen: 2 },       // Berserker Helm
  5: { hp: 10, atk: 0, def: 7, hpPen: 0, atkPen: 1, defPen: 0 },      // Phantom Cloak
  6: { hp: 0, atk: 3, def: 3, hpPen: 0, atkPen: 0, defPen: 0 },       // War Gauntlets
  7: { hp: 0, atk: 6, def: 0, hpPen: 10, atkPen: 0, defPen: 0 },      // Blood Crystal
  8: { hp: 15, atk: 2, def: 2, hpPen: 0, atkPen: 0, defPen: 0 },      // Soul Vessel
};

/**
 * Generate a ZK proof revealing combat stats.
 * Proves player's HP/ATK/DEF are correctly derived from base stats + collected artifacts.
 * Includes inventory commitment verification for artifact ownership.
 *
 * Private inputs: x, y, salt, player_salt, artifact_ids[8], owned_artifacts[8], inventory_salt
 * Public inputs: commitment, stats_commitment, game_id, inventory_commitment
 */
export async function generateCombatRevealProof(
  inputs: CombatRevealInputs
): Promise<CombatRevealResult> {
  const { noir, backend } = await _loadCircuit('combat_reveal');
  const { x, y, salt, playerSalt, artifactIds, ownedArtifacts, inventorySalt, gameId } = inputs;

  // Pad arrays to length 8
  const paddedArtifacts = [...artifactIds];
  while (paddedArtifacts.length < 8) paddedArtifacts.push(0);
  if (paddedArtifacts.length > 8) throw new Error('Too many artifact_ids (max 8)');

  const paddedOwned = [...ownedArtifacts];
  while (paddedOwned.length < 8) paddedOwned.push(0);
  if (paddedOwned.length > 8) throw new Error('Too many owned_artifacts (max 8)');

  // Compute position commitment
  const commitment = await computePedersenHash([
    BigInt(x),
    BigInt(y),
    salt,
  ]);

  // Compute inventory commitment = pedersen(owned_artifacts[0..7], inventory_salt)
  const inventoryCommitment = await computePedersenHash([
    ...paddedOwned.map(id => BigInt(id)),
    inventorySalt,
  ]);

  // Compute stats from base + artifacts (mirrors the circuit logic)
  let hpBonus = 0, atkBonus = 0, defBonus = 0;
  let hpPenalty = 0, atkPenalty = 0, defPenalty = 0;

  for (const aid of paddedArtifacts) {
    const stats = ARTIFACT_STATS[aid] ?? ARTIFACT_STATS[0];
    hpBonus += stats.hp;
    atkBonus += stats.atk;
    defBonus += stats.def;
    hpPenalty += stats.hpPen;
    atkPenalty += stats.atkPen;
    defPenalty += stats.defPen;
  }

  const BASE_HP = 100, BASE_ATK = 10, BASE_DEF = 5;
  let hp = Math.max(1, BASE_HP + hpBonus - hpPenalty);
  let attack = Math.max(1, BASE_ATK + atkBonus - atkPenalty);
  let defense = Math.max(0, BASE_DEF + defBonus - defPenalty);

  // Compute stats commitment = pedersen(hp, attack, defense, player_salt)
  const statsCommitment = await computePedersenHash([
    BigInt(hp),
    BigInt(attack),
    BigInt(defense),
    playerSalt,
  ]);

  const circuitInputs = {
    x: toFieldHex(BigInt(x)),
    y: toFieldHex(BigInt(y)),
    salt: toFieldHex(salt),
    player_salt: toFieldHex(playerSalt),
    artifact_ids: paddedArtifacts.map((id) => String(id)),
    owned_artifacts: paddedOwned.map((id) => String(id)),
    inventory_salt: toFieldHex(inventorySalt),
    commitment,
    stats_commitment: statsCommitment,
    game_id: toFieldHex(gameId),
    inventory_commitment: inventoryCommitment,
  };

  console.log('[ZK] Generating combat_reveal proof…', { x, y, gameId: gameId.toString(), hp, attack, defense });

  const { witness } = await noir.execute(circuitInputs);
  const proof = await backend.generateProof(witness);

  console.log('[ZK] combat_reveal proof generated!', { proofBytes: proof.proof.length });

  return {
    proof: proof.proof,
    publicInputs: [commitment, statsCommitment, toFieldHex(gameId), inventoryCommitment],
    commitment,
    statsCommitment,
    inventoryCommitment,
  };
}

/**
 * Compute an inventory commitment for use with joinGame and claimArtifact.
 * commitment = pedersen(owned_artifacts[0..7], inventory_salt)
 */
export async function computeInventoryCommitment(
  inputs: InventoryCommitmentInputs
): Promise<InventoryCommitmentResult> {
  const { ownedArtifacts, inventorySalt } = inputs;

  const paddedOwned = [...ownedArtifacts];
  while (paddedOwned.length < 8) paddedOwned.push(0);
  if (paddedOwned.length > 8) throw new Error('Too many owned_artifacts (max 8)');

  const commitment = await computePedersenHash([
    ...paddedOwned.map(id => BigInt(id)),
    inventorySalt,
  ]);

  return { commitment };
}

// ── Verification (for debugging) ────────────────────────

/**
 * Verify a proof locally (useful for debugging).
 */
export async function verifyProof(circuitName: CircuitName, proofData: any): Promise<boolean> {
  const { backend } = await _loadCircuit(circuitName);
  try {
    return await backend.verifyProof(proofData);
  } catch (err) {
    console.error(`[ZK] ${circuitName} proof verification failed:`, err);
    return false;
  }
}

// ── Crypto Helpers ──────────────────────────────────────

/**
 * Compute Pedersen hash using Barretenberg.
 * Matches Noir's `std::hash::pedersen_hash` with default separator (0).
 */
export async function computePedersenHash(inputs: bigint[]): Promise<string> {
  const bb = await _getBB();
  const frInputs = inputs.map((v) => bigintToFr(v));
  const result = await bb.pedersenHash({ inputs: frInputs, hashIndex: 0 });
  return frToHex(result.hash);
}

/**
 * Compute Poseidon hash using Barretenberg.
 * Matches Noir's `poseidon::poseidon::bn254::hash_N` functions.
 * Used for nullifier derivation in claim_artifact.
 */
export async function computePoseidonHash(inputs: bigint[]): Promise<string> {
  const bb = await _getBB();
  const frInputs = inputs.map((v) => bigintToFr(v));
  // Barretenberg's poseidonHash function
  const result = await bb.poseidonHash(frInputs);
  return frToHex(result);
}

/**
 * Convert a bigint to a 32-byte big-endian Uint8Array (Fr field element).
 */
function bigintToFr(value: bigint): Uint8Array {
  const hex = value.toString(16).padStart(64, '0');
  const bytes = new Uint8Array(32);
  for (let i = 0; i < 32; i++) {
    bytes[i] = parseInt(hex.substring(i * 2, i * 2 + 2), 16);
  }
  return bytes;
}

/**
 * Convert a 32-byte Uint8Array to a 0x-prefixed hex string.
 */
function frToHex(fr: Uint8Array): string {
  return '0x' + Array.from(fr).map((b) => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Convert a bigint to a 0x-prefixed hex string (field element, 32 bytes).
 */
export function toFieldHex(value: bigint): string {
  return '0x' + value.toString(16).padStart(64, '0');
}

/**
 * Generate a cryptographically random salt (field element).
 * Uses 31 bytes to stay safely within the BN254 scalar field.
 */
export function randomSalt(): bigint {
  const bytes = new Uint8Array(31);
  crypto.getRandomValues(bytes);
  let result = BigInt(0);
  for (const b of bytes) {
    result = (result << BigInt(8)) | BigInt(b);
  }
  return result;
}

/**
 * Convert a proof Uint8Array to a hex string for on-chain submission.
 */
export function proofToHex(proof: Uint8Array): `0x${string}` {
  return ('0x' + Array.from(proof).map((b) => b.toString(16).padStart(2, '0')).join('')) as `0x${string}`;
}

/**
 * Convert publicInputs string array to bytes32[] for on-chain submission.
 */
export function publicInputsToBytes32(inputs: string[]): `0x${string}`[] {
  return inputs.map((s) => {
    // Ensure each input is padded to 32 bytes (64 hex chars)
    const clean = s.startsWith('0x') ? s.slice(2) : s;
    return ('0x' + clean.padStart(64, '0')) as `0x${string}`;
  });
}
