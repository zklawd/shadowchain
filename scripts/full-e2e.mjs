#!/usr/bin/env node
/**
 * Full E2E Test - Creates game, joins with known secrets, submits real ZK proofs
 */

import { Noir } from '@noir-lang/noir_js';
import { UltraHonkBackend, Barretenberg, Fr } from '@aztec/bb.js';

// Shared Barretenberg instance
let _bb = null;
async function getBB() {
  if (_bb) return _bb;
  _bb = await Barretenberg.new();
  return _bb;
}
import { createPublicClient, createWalletClient, http, encodeFunctionData, keccak256, toBytes, toHex, concat } from 'viem';
import { sepolia } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';
import { readFileSync } from 'fs';
import { execSync } from 'child_process';
import { createHash, randomBytes } from 'crypto';

const GAME_ADDRESS = '0xfE06900CEa98ca4D6F23Bc2fC1C39b51E0B89d9c';
const RPC_URL = 'https://ethereum-sepolia-rpc.publicnode.com';

// Full ABI
const GAME_ABI = [
  {
    name: 'createGame',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'seed', type: 'uint256' },
      { name: 'maxPlayers', type: 'uint8' },
      { name: 'entryFee', type: 'uint256' }
    ],
    outputs: [{ name: 'gameId', type: 'uint256' }]
  },
  {
    name: 'joinGame',
    type: 'function',
    stateMutability: 'payable',
    inputs: [
      { name: 'gameId', type: 'uint256' },
      { name: 'commitment', type: 'bytes32' },
      { name: 'inventoryCommitment', type: 'bytes32' }
    ],
    outputs: []
  },
  {
    name: 'startGame',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [{ name: 'gameId', type: 'uint256' }],
    outputs: []
  },
  {
    name: 'submitMove',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'gameId', type: 'uint256' },
      { name: 'newCommitment', type: 'bytes32' },
      { name: 'proof', type: 'bytes' },
      { name: 'publicInputs', type: 'bytes32[]' }
    ],
    outputs: []
  },
  {
    name: 'getGame',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'gameId', type: 'uint256' }],
    outputs: [{
      name: '',
      type: 'tuple',
      components: [
        { name: 'id', type: 'uint256' },
        { name: 'seed', type: 'uint256' },
        { name: 'entryFee', type: 'uint256' },
        { name: 'prizePool', type: 'uint256' },
        { name: 'wallBitmap', type: 'uint256' },
        { name: 'treasureSeed', type: 'bytes32' },
        { name: 'currentTurn', type: 'uint16' },
        { name: 'maxTurns', type: 'uint16' },
        { name: 'maxPlayers', type: 'uint8' },
        { name: 'playerCount', type: 'uint8' },
        { name: 'aliveCount', type: 'uint8' },
        { name: 'turnDeadline', type: 'uint256' },
        { name: 'creator', type: 'address' },
        { name: 'winner', type: 'address' },
        { name: 'state', type: 'uint8' },
      ]
    }]
  },
  {
    name: 'getPlayer',
    type: 'function',
    stateMutability: 'view',
    inputs: [
      { name: 'gameId', type: 'uint256' },
      { name: 'addr', type: 'address' }
    ],
    outputs: [{
      name: '',
      type: 'tuple',
      components: [
        { name: 'addr', type: 'address' },
        { name: 'commitment', type: 'bytes32' },
        { name: 'hp', type: 'uint16' },
        { name: 'attack', type: 'uint8' },
        { name: 'defense', type: 'uint8' },
        { name: 'status', type: 'uint8' },
        { name: 'hasSubmittedThisTurn', type: 'bool' },
      ]
    }]
  },
  {
    name: 'nextGameId',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }]
  },
  {
    name: 'isTreasure',
    type: 'function',
    stateMutability: 'view',
    inputs: [
      { name: 'gameId', type: 'uint256' },
      { name: 'x', type: 'uint8' },
      { name: 'y', type: 'uint8' }
    ],
    outputs: [{ name: '', type: 'bool' }]
  },
];

// Circuit cache
const circuits = {};

async function loadCircuit(name) {
  if (circuits[name]) return circuits[name];
  
  const circuitPath = `./circuits/${name}/target/${name}.json`;
  const circuit = JSON.parse(readFileSync(circuitPath, 'utf8'));
  const noir = new Noir(circuit);
  // bb.js 0.82.2: UltraHonkBackend creates its own Barretenberg instance
  const backend = new UltraHonkBackend(circuit.bytecode);
  circuits[name] = { noir, backend };
  return circuits[name];
}

// Get private key
function getPrivateKey(account, password) {
  const castPath = `${process.env.HOME}/.foundry/bin/cast`;
  const result = execSync(
    `${castPath} wallet decrypt-keystore ${account} --unsafe-password "${password}"`,
    { encoding: 'utf8' }
  );
  const match = result.match(/0x[a-fA-F0-9]{64}/);
  if (!match) throw new Error('Failed to extract private key');
  return match[0];
}

// BN254 field modulus
const FIELD_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617n;

// Generate random salt (must be < field modulus)
function randomSalt() {
  const bytes = randomBytes(31); // Use 31 bytes to stay under modulus
  return BigInt('0x' + bytes.toString('hex')) % FIELD_MODULUS;
}

// Convert to 32-byte hex
function toHex32(val) {
  return '0x' + BigInt(val).toString(16).padStart(64, '0');
}

// Convert bigint to 32-byte Uint8Array (Fr field element)
function bigintToFr(value) {
  const hex = value.toString(16).padStart(64, '0');
  const bytes = new Uint8Array(32);
  for (let i = 0; i < 32; i++) {
    bytes[i] = parseInt(hex.substring(i * 2, i * 2 + 2), 16);
  }
  return bytes;
}

// Convert Uint8Array to hex string
function frToHex(bytes) {
  return '0x' + Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
}

// Pedersen hash using bb.js 0.82.2 API
async function computeCommitment(x, y, salt) {
  const bb = await getBB();
  
  // Ensure salt is a bigint and within field bounds
  const saltBigInt = BigInt(salt) % FIELD_MODULUS;
  
  // Create Fr elements from bigints
  const xFr = Fr.fromBuffer(Buffer.from(BigInt(x).toString(16).padStart(64, '0'), 'hex'));
  const yFr = Fr.fromBuffer(Buffer.from(BigInt(y).toString(16).padStart(64, '0'), 'hex'));
  const saltFr = Fr.fromBuffer(Buffer.from(saltBigInt.toString(16).padStart(64, '0'), 'hex'));
  
  const hash = await bb.pedersenHash([xFr, yFr, saltFr], 0);
  const hashHex = Buffer.from(hash.toBuffer()).toString('hex');
  
  return '0x' + hashHex.padStart(64, '0');
}

// Generate wall bitmasks from bitmap
function wallBitmapToRows(bitmap) {
  const rows = [];
  for (let y = 0; y < 16; y++) {
    let rowBits = 0n;
    for (let x = 0; x < 16; x++) {
      const idx = BigInt(y * 16 + x);
      if ((bitmap >> idx) & 1n) {
        rowBits |= 1n << BigInt(x);
      }
    }
    rows.push(rowBits.toString());
  }
  return rows;
}

// Check if a cell is a wall
function isWall(bitmap, x, y) {
  const idx = BigInt(y * 16 + x);
  return ((bitmap >> idx) & 1n) === 1n;
}

// Find a valid spawn position (not a wall)
function findValidSpawn(wallBitmap) {
  for (let x = 5; x < 10; x++) {
    for (let y = 5; y < 10; y++) {
      if (!isWall(wallBitmap, x, y)) {
        return { x, y };
      }
    }
  }
  return { x: 8, y: 8 }; // fallback
}

async function main() {
  console.log('🎮 ShadowChain Full E2E Test\n');
  
  // Setup wallet
  console.log('🔑 Loading wallet...');
  const privateKey = getPrivateKey('zklawd', 'zklawd-temp');
  const account = privateKeyToAccount(privateKey);
  console.log(`   Address: ${account.address}\n`);
  
  const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(RPC_URL),
  });
  
  const walletClient = createWalletClient({
    account,
    chain: sepolia,
    transport: http(RPC_URL),
  });
  
  // Get next game ID
  const nextGameId = await publicClient.readContract({
    address: GAME_ADDRESS,
    abi: GAME_ABI,
    functionName: 'nextGameId',
  });
  console.log(`📊 Next game ID: ${nextGameId}\n`);
  
  // Step 1: Create game
  console.log('1️⃣ Creating game...');
  const seed = BigInt(Date.now());
  const createTx = await walletClient.writeContract({
    address: GAME_ADDRESS,
    abi: GAME_ABI,
    functionName: 'createGame',
    args: [seed, 2, 0n], // 2 players, no entry fee
  });
  console.log(`   TX: ${createTx}`);
  await publicClient.waitForTransactionReceipt({ hash: createTx });
  
  const gameId = nextGameId;
  console.log(`   Game ${gameId} created!\n`);
  
  // Get game data to find walls
  const game = await publicClient.readContract({
    address: GAME_ADDRESS,
    abi: GAME_ABI,
    functionName: 'getGame',
    args: [gameId],
  });
  
  // Step 2: Generate position commitment
  console.log('2️⃣ Generating position commitment...');
  const spawn = findValidSpawn(game.wallBitmap);
  const salt = randomSalt();
  const inventorySalt = randomSalt();
  
  console.log(`   Spawn position: (${spawn.x}, ${spawn.y})`);
  console.log(`   Salt: ${toHex32(salt).slice(0, 18)}...`);
  
  // Compute commitment
  const commitment = await computeCommitment(spawn.x, spawn.y, salt);
  console.log(`   Commitment: ${commitment.slice(0, 18)}...\n`);
  
  // Compute inventory commitment (empty inventory + salt)
  // For simplicity in testing, use a deterministic commitment
  const invCommitmentHex = toHex32(randomSalt()); // Placeholder - real implementation would compute pedersen
  
  // Step 3: Join game
  console.log('3️⃣ Joining game...');
  const joinTx = await walletClient.writeContract({
    address: GAME_ADDRESS,
    abi: GAME_ABI,
    functionName: 'joinGame',
    args: [gameId, commitment, invCommitmentHex],
  });
  console.log(`   TX: ${joinTx}`);
  await publicClient.waitForTransactionReceipt({ hash: joinTx });
  console.log(`   Joined!\n`);
  
  // Join with second player (dev wallet)
  console.log('3️⃣ Joining with second player...');
  const privateKey2 = getPrivateKey('zklawd-dev', 'zklawd-dev');
  const account2 = privateKeyToAccount(privateKey2);
  const walletClient2 = createWalletClient({
    account: account2,
    chain: sepolia,
    transport: http(RPC_URL),
  });
  
  const spawn2 = { x: spawn.x + 2, y: spawn.y + 2 };
  const salt2 = randomSalt();
  const commitment2 = await computeCommitment(spawn2.x, spawn2.y, salt2);
  const inventorySalt2 = randomSalt();
  
  const invCommitmentHex2 = toHex32(randomSalt()); // Placeholder
  
  const join2Tx = await walletClient2.writeContract({
    address: GAME_ADDRESS,
    abi: GAME_ABI,
    functionName: 'joinGame',
    args: [gameId, commitment2, invCommitmentHex2],
  });
  console.log(`   TX: ${join2Tx}`);
  await publicClient.waitForTransactionReceipt({ hash: join2Tx });
  console.log(`   Player 2 joined!\n`);
  
  // Step 4: Start game (may auto-start if full)
  console.log('4️⃣ Starting game...');
  let gameStarted = await publicClient.readContract({
    address: GAME_ADDRESS,
    abi: GAME_ABI,
    functionName: 'getGame',
    args: [gameId],
  });
  
  if (gameStarted.state === 0) { // Created state
    const startTx = await walletClient.writeContract({
      address: GAME_ADDRESS,
      abi: GAME_ABI,
      functionName: 'startGame',
      args: [gameId],
    });
    console.log(`   TX: ${startTx}`);
    await publicClient.waitForTransactionReceipt({ hash: startTx });
    console.log(`   Game started!\n`);
    
    gameStarted = await publicClient.readContract({
      address: GAME_ADDRESS,
      abi: GAME_ABI,
      functionName: 'getGame',
      args: [gameId],
    });
  } else {
    console.log(`   Game already in state ${gameStarted.state} (auto-started when full)\n`);
  }
  
  console.log(`   Treasure seed: ${gameStarted.treasureSeed.slice(0, 18)}...\n`);
  
  // Step 5: Generate and submit move proof
  console.log('5️⃣ Generating move proof...');
  const newSalt = randomSalt();
  
  // Find a valid adjacent cell that's not a wall
  const directions = [[0, 1], [0, -1], [1, 0], [-1, 0]]; // down, up, right, left
  let newX = spawn.x, newY = spawn.y;
  let foundValid = false;
  
  for (const [dx, dy] of directions) {
    const testX = spawn.x + dx;
    const testY = spawn.y + dy;
    if (testX >= 0 && testX < 16 && testY >= 0 && testY < 16 && !isWall(gameStarted.wallBitmap, testX, testY)) {
      newX = testX;
      newY = testY;
      foundValid = true;
      break;
    }
  }
  
  if (!foundValid) {
    console.log('   ⚠️ No valid adjacent cell found, staying in place');
  }
  
  console.log(`   Moving from (${spawn.x}, ${spawn.y}) to (${newX}, ${newY})`);
  
  // Compute new commitment
  const newCommitment = await computeCommitment(newX, newY, newSalt);
  console.log(`   New commitment: ${newCommitment.slice(0, 18)}...`);
  
  // Load valid_move circuit
  const { noir, backend } = await loadCircuit('valid_move');
  
  // Prepare circuit inputs
  const mapWalls = wallBitmapToRows(gameStarted.wallBitmap);
  const mapWallsHex = mapWalls.map(w => toHex32(BigInt(w)));
  
  console.log(`   Map walls: [${mapWalls.length} rows]`);
  
  const circuitInputs = {
    old_x: spawn.x.toString(),
    old_y: spawn.y.toString(),
    old_salt: toHex32(salt),
    new_x: newX.toString(),
    new_y: newY.toString(),
    new_salt: toHex32(newSalt),
    old_commitment: commitment,
    new_commitment: newCommitment,
    map_walls: mapWallsHex,
  };
  
  console.log('   Executing circuit...');
  const { witness } = await noir.execute(circuitInputs);
  
  console.log('   Generating proof...');
  const proof = await backend.generateProof(witness, { keccak: true });
  console.log(`   Proof size: ${proof.proof.length} bytes\n`);
  
  // Convert proof to hex
  const proofHex = '0x' + Buffer.from(proof.proof).toString('hex');
  // Public inputs: old_commitment, new_commitment, 16 map_walls entries
  const publicInputs = [commitment, newCommitment, ...mapWallsHex];
  
  // Step 6: Submit move
  console.log('6️⃣ Submitting move on-chain...');
  try {
    const moveTx = await walletClient.writeContract({
      address: GAME_ADDRESS,
      abi: GAME_ABI,
      functionName: 'submitMove',
      args: [gameId, newCommitment, proofHex, publicInputs],
    });
    console.log(`   TX: ${moveTx}`);
    const receipt = await publicClient.waitForTransactionReceipt({ hash: moveTx });
    console.log(`   Status: ${receipt.status === 'success' ? '✅ SUCCESS' : '❌ FAILED'}\n`);
  } catch (e) {
    console.log(`   ❌ Error: ${e.message}\n`);
  }
  
  // Verify player state
  const playerAfter = await publicClient.readContract({
    address: GAME_ADDRESS,
    abi: GAME_ABI,
    functionName: 'getPlayer',
    args: [gameId, account.address],
  });
  
  console.log('📊 Final player state:');
  console.log(`   Commitment: ${playerAfter.commitment.slice(0, 18)}...`);
  console.log(`   Submitted: ${playerAfter.hasSubmittedThisTurn}`);
  console.log(`   HP: ${playerAfter.hp}, ATK: ${playerAfter.attack}, DEF: ${playerAfter.defense}`);
  
  console.log('\n✅ E2E test complete!');
}

main().catch(e => {
  console.error('❌ Error:', e.message);
  process.exit(1);
});
