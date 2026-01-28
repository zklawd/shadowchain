/**
 * Browser-based ZK proof generation using Noir 1.0.0-beta.18 + Barretenberg.
 *
 * Lazily initializes WASM-based Noir execution engine and Barretenberg
 * UltraHonk proving backend, then exposes a simple API for generating
 * valid_move proofs in the browser.
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

// ── Internal state ───────────────────────────────────────

let _initialized = false;
let _initPromise: Promise<void> | null = null;
let _noir: any = null;
let _backend: any = null;
let _bb: any = null; // Barretenberg instance for crypto utils

// ── Initialization ───────────────────────────────────────

async function _init(): Promise<void> {
  console.log('[ZK] Initializing WASM prover…');

  // 1. Initialize WASM modules from public/ folder
  const [{ default: initACVM }, { default: initNoirC }] = await Promise.all([
    import('@noir-lang/acvm_js'),
    import('@noir-lang/noirc_abi'),
  ]);

  await Promise.all([
    initACVM(fetch('/wasm/acvm_js_bg.wasm')),
    initNoirC(fetch('/wasm/noirc_abi_wasm_bg.wasm')),
  ]);
  console.log('[ZK] WASM modules initialized');

  // 2. Load the compiled circuit artifact
  const res = await fetch('/circuits/valid_move.json');
  if (!res.ok) throw new Error(`Failed to load circuit: ${res.status}`);
  const circuit = await res.json();
  console.log('[ZK] Circuit loaded:', circuit.noir_version);

  // 3. Instantiate Noir executor
  const { Noir } = await import('@noir-lang/noir_js');
  _noir = new Noir(circuit);

  // 4. Instantiate Barretenberg
  const { Barretenberg, UltraHonkBackend } = await import('@aztec/bb.js');
  _bb = await Barretenberg.new();
  _backend = new UltraHonkBackend(circuit.bytecode, _bb);

  console.log('[ZK] Prover ready (UltraHonk backend)');
}

/**
 * Ensure the prover is initialized. Safe to call multiple times.
 */
export async function initProver(): Promise<void> {
  if (_initialized) return;
  if (!_initPromise) {
    _initPromise = _init().then(() => {
      _initialized = true;
    }).catch((err) => {
      _initPromise = null; // allow retry on failure
      throw err;
    });
  }
  return _initPromise;
}

/**
 * Check if the prover has finished initializing.
 */
export function isProverReady(): boolean {
  return _initialized;
}

// ── Proof generation ─────────────────────────────────────

/**
 * Generate a ZK proof for a valid move.
 *
 * Private inputs: old position + salt, new position + salt
 * Public inputs: old commitment, new commitment, map wall bitmasks
 */
export async function generateMoveProof(inputs: MoveProofInputs): Promise<MoveProofResult> {
  await initProver();

  const { oldPos, newPos, oldSalt, newSalt, mapWalls } = inputs;

  // Compute Pedersen commitments using Barretenberg
  // Noir's pedersen_hash([x, y, salt]) with default separator (hashIndex=0)
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

  // Format map_walls as array of field strings
  const mapWallsArr = mapWalls.map((w) => toFieldHex(w));

  // Build the full circuit inputs
  const circuitInputs = {
    old_x: toFieldHex(BigInt(oldPos.x)),
    old_y: toFieldHex(BigInt(oldPos.y)),
    old_salt: toFieldHex(oldSalt),
    new_x: toFieldHex(BigInt(newPos.x)),
    new_y: toFieldHex(BigInt(newPos.y)),
    new_salt: toFieldHex(newSalt),
    old_commitment: oldCommitment,
    new_commitment: newCommitment,
    map_walls: mapWallsArr,
  };

  console.log('[ZK] Executing circuit…', {
    from: `(${oldPos.x}, ${oldPos.y})`,
    to: `(${newPos.x}, ${newPos.y})`,
  });

  // Execute circuit to generate witness
  const { witness } = await _noir.execute(circuitInputs);
  console.log('[ZK] Witness generated, proving…');

  // Generate UltraHonk proof
  const proof = await _backend.generateProof(witness);
  console.log('[ZK] Proof generated!', { proofBytes: proof.proof.length });

  return {
    proof: proof.proof,
    publicInputs: [oldCommitment, newCommitment, ...mapWallsArr],
    oldCommitment,
    newCommitment,
  };
}

/**
 * Verify a proof locally (useful for debugging).
 */
export async function verifyMoveProof(proof: any): Promise<boolean> {
  await initProver();
  try {
    return await _backend.verifyProof(proof);
  } catch (err) {
    console.error('[ZK] Proof verification failed:', err);
    return false;
  }
}

// ── Crypto helpers ───────────────────────────────────────

/**
 * Compute Pedersen hash using Barretenberg.
 * Matches Noir's `std::hash::pedersen_hash` with default separator (0).
 *
 * bb.pedersenHash({ inputs: Uint8Array[], hashIndex: number }) → { hash: Uint8Array }
 */
async function computePedersenHash(inputs: bigint[]): Promise<string> {
  const frInputs = inputs.map((v) => bigintToFr(v));
  const result = await _bb.pedersenHash({ inputs: frInputs, hashIndex: 0 });
  return frToHex(result.hash);
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
 * Convert a bigint to a 0x-prefixed hex string (field element).
 */
function toFieldHex(value: bigint): string {
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
