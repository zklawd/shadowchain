import { type Abi } from 'viem';

// ── Contract Addresses ─────────────────────────────────────

export const SHADOW_CHAIN_GAME_ADDRESS = '0x14858891533335c50825915b54932B8991Af011C' as const;
export const ARTIFACT_REGISTRY_ADDRESS = '0x8103b517515e07df74e0f02c76b04caeCA502290' as const;
export const VALID_MOVE_VERIFIER_ADDRESS = '0x495A19Bc734dfAbA95EB29FAbd1f99400900D362' as const;
export const CLAIM_ARTIFACT_VERIFIER_ADDRESS = '0x8218EBd4003B9F4A3FDFcE2694684494b0945166' as const;
export const COMBAT_REVEAL_VERIFIER_ADDRESS = '0x17F8e80a6E24b875ec83c239223eED5d853DB4EB' as const;

// ── ShadowChainGame ABI ────────────────────────────────────

export const shadowChainGameAbi = [
  { type: 'constructor', inputs: [{ name: '_moveVerifier', type: 'address', internalType: 'address' }, { name: '_artifactVerifier', type: 'address', internalType: 'address' }, { name: '_combatVerifier', type: 'address', internalType: 'address' }, { name: '_artifactRegistry', type: 'address', internalType: 'address' }], stateMutability: 'nonpayable' },
  { type: 'receive', stateMutability: 'payable' },
  { type: 'function', name: 'DEFAULT_MAX_TURNS', inputs: [], outputs: [{ name: '', type: 'uint32', internalType: 'uint32' }], stateMutability: 'view' },
  { type: 'function', name: 'MAX_PLAYERS_LIMIT', inputs: [], outputs: [{ name: '', type: 'uint8', internalType: 'uint8' }], stateMutability: 'view' },
  { type: 'function', name: 'MIN_PLAYERS', inputs: [], outputs: [{ name: '', type: 'uint8', internalType: 'uint8' }], stateMutability: 'view' },
  { type: 'function', name: 'TURN_DURATION', inputs: [], outputs: [{ name: '', type: 'uint32', internalType: 'uint32' }], stateMutability: 'view' },
  { type: 'function', name: 'advanceTurn', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }], outputs: [], stateMutability: 'nonpayable' },
  { type: 'function', name: 'artifactRegistry', inputs: [], outputs: [{ name: '', type: 'address', internalType: 'address' }], stateMutability: 'view' },
  { type: 'function', name: 'artifactVerifier', inputs: [], outputs: [{ name: '', type: 'address', internalType: 'address' }], stateMutability: 'view' },
  { type: 'function', name: 'claimArtifact', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }, { name: 'treasureCellIndex', type: 'uint8', internalType: 'uint8' }, { name: 'proof', type: 'bytes', internalType: 'bytes' }, { name: 'publicInputs', type: 'bytes32[]', internalType: 'bytes32[]' }], outputs: [], stateMutability: 'nonpayable' },
  { type: 'function', name: 'combatVerifier', inputs: [], outputs: [{ name: '', type: 'address', internalType: 'address' }], stateMutability: 'view' },
  { type: 'function', name: 'createGame', inputs: [{ name: 'seed', type: 'uint256', internalType: 'uint256' }, { name: 'maxPlayers', type: 'uint8', internalType: 'uint8' }, { name: 'entryFee', type: 'uint256', internalType: 'uint256' }], outputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }], stateMutability: 'nonpayable' },
  { type: 'function', name: 'forfeit', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }], outputs: [], stateMutability: 'nonpayable' },
  { type: 'function', name: 'games', inputs: [{ name: '', type: 'uint256', internalType: 'uint256' }], outputs: [{ name: 'id', type: 'uint256', internalType: 'uint256' }, { name: 'seed', type: 'uint256', internalType: 'uint256' }, { name: 'entryFee', type: 'uint256', internalType: 'uint256' }, { name: 'prizePool', type: 'uint256', internalType: 'uint256' }, { name: 'wallBitmap', type: 'uint256', internalType: 'uint256' }, { name: 'treasureBitmap', type: 'uint256', internalType: 'uint256' }, { name: 'currentTurn', type: 'uint32', internalType: 'uint32' }, { name: 'maxTurns', type: 'uint32', internalType: 'uint32' }, { name: 'maxPlayers', type: 'uint8', internalType: 'uint8' }, { name: 'playerCount', type: 'uint8', internalType: 'uint8' }, { name: 'aliveCount', type: 'uint8', internalType: 'uint8' }, { name: 'turnDeadline', type: 'uint64', internalType: 'uint64' }, { name: 'creator', type: 'address', internalType: 'address' }, { name: 'winner', type: 'address', internalType: 'address' }, { name: 'state', type: 'uint8', internalType: 'uint8' }], stateMutability: 'view' },
  { type: 'function', name: 'getGame', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }], outputs: [{ name: '', type: 'tuple', internalType: 'struct ShadowChainGame.Game', components: [{ name: 'id', type: 'uint256', internalType: 'uint256' }, { name: 'seed', type: 'uint256', internalType: 'uint256' }, { name: 'entryFee', type: 'uint256', internalType: 'uint256' }, { name: 'prizePool', type: 'uint256', internalType: 'uint256' }, { name: 'wallBitmap', type: 'uint256', internalType: 'uint256' }, { name: 'treasureBitmap', type: 'uint256', internalType: 'uint256' }, { name: 'currentTurn', type: 'uint32', internalType: 'uint32' }, { name: 'maxTurns', type: 'uint32', internalType: 'uint32' }, { name: 'maxPlayers', type: 'uint8', internalType: 'uint8' }, { name: 'playerCount', type: 'uint8', internalType: 'uint8' }, { name: 'aliveCount', type: 'uint8', internalType: 'uint8' }, { name: 'turnDeadline', type: 'uint64', internalType: 'uint64' }, { name: 'creator', type: 'address', internalType: 'address' }, { name: 'winner', type: 'address', internalType: 'address' }, { name: 'state', type: 'uint8', internalType: 'uint8' }] }], stateMutability: 'view' },
  { type: 'function', name: 'getGameMap', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }], outputs: [{ name: 'wallBitmap', type: 'uint256', internalType: 'uint256' }, { name: 'treasureBitmap', type: 'uint256', internalType: 'uint256' }], stateMutability: 'view' },
  { type: 'function', name: 'getPlayer', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }, { name: 'addr', type: 'address', internalType: 'address' }], outputs: [{ name: '', type: 'tuple', internalType: 'struct ShadowChainGame.Player', components: [{ name: 'addr', type: 'address', internalType: 'address' }, { name: 'commitment', type: 'bytes32', internalType: 'bytes32' }, { name: 'hp', type: 'int16', internalType: 'int16' }, { name: 'attack', type: 'int8', internalType: 'int8' }, { name: 'defense', type: 'int8', internalType: 'int8' }, { name: 'status', type: 'uint8', internalType: 'uint8' }, { name: 'hasSubmittedThisTurn', type: 'bool', internalType: 'bool' }] }], stateMutability: 'view' },
  { type: 'function', name: 'isTreasure', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }, { name: 'x', type: 'uint8', internalType: 'uint8' }, { name: 'y', type: 'uint8', internalType: 'uint8' }], outputs: [{ name: '', type: 'bool', internalType: 'bool' }], stateMutability: 'view' },
  { type: 'function', name: 'isWall', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }, { name: 'x', type: 'uint8', internalType: 'uint8' }, { name: 'y', type: 'uint8', internalType: 'uint8' }], outputs: [{ name: '', type: 'bool', internalType: 'bool' }], stateMutability: 'view' },
  { type: 'function', name: 'joinGame', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }, { name: 'commitment', type: 'bytes32', internalType: 'bytes32' }], outputs: [], stateMutability: 'payable' },
  { type: 'function', name: 'moveVerifier', inputs: [], outputs: [{ name: '', type: 'address', internalType: 'address' }], stateMutability: 'view' },
  { type: 'function', name: 'nextGameId', inputs: [], outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }], stateMutability: 'view' },
  { type: 'function', name: 'playerByIndex', inputs: [{ name: '', type: 'uint256', internalType: 'uint256' }, { name: '', type: 'uint8', internalType: 'uint8' }], outputs: [{ name: '', type: 'address', internalType: 'address' }], stateMutability: 'view' },
  { type: 'function', name: 'players', inputs: [{ name: '', type: 'uint256', internalType: 'uint256' }, { name: '', type: 'address', internalType: 'address' }], outputs: [{ name: 'addr', type: 'address', internalType: 'address' }, { name: 'commitment', type: 'bytes32', internalType: 'bytes32' }, { name: 'hp', type: 'int16', internalType: 'int16' }, { name: 'attack', type: 'int8', internalType: 'int8' }, { name: 'defense', type: 'int8', internalType: 'int8' }, { name: 'status', type: 'uint8', internalType: 'uint8' }, { name: 'hasSubmittedThisTurn', type: 'bool', internalType: 'bool' }], stateMutability: 'view' },
  { type: 'function', name: 'resolveGame', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }], outputs: [], stateMutability: 'nonpayable' },
  { type: 'function', name: 'startGame', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }], outputs: [], stateMutability: 'nonpayable' },
  { type: 'function', name: 'submitMove', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }, { name: 'newCommitment', type: 'bytes32', internalType: 'bytes32' }, { name: 'proof', type: 'bytes', internalType: 'bytes' }, { name: 'publicInputs', type: 'bytes32[]', internalType: 'bytes32[]' }], outputs: [], stateMutability: 'nonpayable' },
  { type: 'function', name: 'triggerCombat', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }, { name: 'defender', type: 'address', internalType: 'address' }, { name: 'proof', type: 'bytes', internalType: 'bytes' }, { name: 'publicInputs', type: 'bytes32[]', internalType: 'bytes32[]' }], outputs: [], stateMutability: 'nonpayable' },
  { type: 'event', name: 'ArtifactClaimedEvent', inputs: [{ name: 'gameId', type: 'uint256', indexed: true, internalType: 'uint256' }, { name: 'player', type: 'address', indexed: true, internalType: 'address' }, { name: 'artifactId', type: 'uint8', indexed: false, internalType: 'uint8' }, { name: 'cellIndex', type: 'uint8', indexed: false, internalType: 'uint8' }], anonymous: false },
  { type: 'event', name: 'CombatTriggered', inputs: [{ name: 'gameId', type: 'uint256', indexed: true, internalType: 'uint256' }, { name: 'attacker', type: 'address', indexed: true, internalType: 'address' }, { name: 'defender', type: 'address', indexed: true, internalType: 'address' }, { name: 'damage', type: 'int16', indexed: false, internalType: 'int16' }, { name: 'defenderEliminated', type: 'bool', indexed: false, internalType: 'bool' }], anonymous: false },
  { type: 'event', name: 'GameCreated', inputs: [{ name: 'gameId', type: 'uint256', indexed: true, internalType: 'uint256' }, { name: 'creator', type: 'address', indexed: true, internalType: 'address' }, { name: 'seed', type: 'uint256', indexed: false, internalType: 'uint256' }, { name: 'maxPlayers', type: 'uint8', indexed: false, internalType: 'uint8' }, { name: 'entryFee', type: 'uint256', indexed: false, internalType: 'uint256' }], anonymous: false },
  { type: 'event', name: 'GameResolved', inputs: [{ name: 'gameId', type: 'uint256', indexed: true, internalType: 'uint256' }, { name: 'winner', type: 'address', indexed: true, internalType: 'address' }, { name: 'prize', type: 'uint256', indexed: false, internalType: 'uint256' }], anonymous: false },
  { type: 'event', name: 'GameStarted', inputs: [{ name: 'gameId', type: 'uint256', indexed: true, internalType: 'uint256' }, { name: 'maxTurns', type: 'uint32', indexed: false, internalType: 'uint32' }, { name: 'firstTurnDeadline', type: 'uint64', indexed: false, internalType: 'uint64' }], anonymous: false },
  { type: 'event', name: 'MoveSubmitted', inputs: [{ name: 'gameId', type: 'uint256', indexed: true, internalType: 'uint256' }, { name: 'player', type: 'address', indexed: true, internalType: 'address' }, { name: 'turn', type: 'uint32', indexed: false, internalType: 'uint32' }, { name: 'newCommitment', type: 'bytes32', indexed: false, internalType: 'bytes32' }], anonymous: false },
  { type: 'event', name: 'PlayerEliminated', inputs: [{ name: 'gameId', type: 'uint256', indexed: true, internalType: 'uint256' }, { name: 'player', type: 'address', indexed: true, internalType: 'address' }, { name: 'turn', type: 'uint32', indexed: false, internalType: 'uint32' }], anonymous: false },
  { type: 'event', name: 'PlayerForfeited', inputs: [{ name: 'gameId', type: 'uint256', indexed: true, internalType: 'uint256' }, { name: 'player', type: 'address', indexed: true, internalType: 'address' }, { name: 'turn', type: 'uint32', indexed: false, internalType: 'uint32' }], anonymous: false },
  { type: 'event', name: 'PlayerJoined', inputs: [{ name: 'gameId', type: 'uint256', indexed: true, internalType: 'uint256' }, { name: 'player', type: 'address', indexed: true, internalType: 'address' }, { name: 'playerIndex', type: 'uint8', indexed: false, internalType: 'uint8' }], anonymous: false },
  { type: 'event', name: 'TurnAdvanced', inputs: [{ name: 'gameId', type: 'uint256', indexed: true, internalType: 'uint256' }, { name: 'newTurn', type: 'uint32', indexed: false, internalType: 'uint32' }, { name: 'newDeadline', type: 'uint64', indexed: false, internalType: 'uint64' }], anonymous: false },
  { type: 'error', name: 'ReentrancyGuardReentrantCall', inputs: [] },
] as const;

// ── ArtifactRegistry ABI ───────────────────────────────────

export const artifactRegistryAbi = [
  { type: 'function', name: 'BASE_ATTACK', inputs: [], outputs: [{ name: '', type: 'int8', internalType: 'int8' }], stateMutability: 'view' },
  { type: 'function', name: 'BASE_DEFENSE', inputs: [], outputs: [{ name: '', type: 'int8', internalType: 'int8' }], stateMutability: 'view' },
  { type: 'function', name: 'BASE_HP', inputs: [], outputs: [{ name: '', type: 'int16', internalType: 'int16' }], stateMutability: 'view' },
  { type: 'function', name: 'NUM_ARTIFACTS', inputs: [], outputs: [{ name: '', type: 'uint8', internalType: 'uint8' }], stateMutability: 'view' },
  { type: 'function', name: 'assignArtifacts', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }, { name: 'seed', type: 'uint256', internalType: 'uint256' }, { name: 'treasureCellIndices', type: 'uint8[]', internalType: 'uint8[]' }], outputs: [], stateMutability: 'nonpayable' },
  { type: 'function', name: 'cellArtifact', inputs: [{ name: '', type: 'uint256', internalType: 'uint256' }, { name: '', type: 'uint8', internalType: 'uint8' }], outputs: [{ name: '', type: 'uint8', internalType: 'uint8' }], stateMutability: 'view' },
  { type: 'function', name: 'claimArtifact', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }, { name: 'player', type: 'address', internalType: 'address' }, { name: 'treasureCellIndex', type: 'uint8', internalType: 'uint8' }], outputs: [{ name: 'artifactId', type: 'uint8', internalType: 'uint8' }], stateMutability: 'nonpayable' },
  { type: 'function', name: 'claimedBy', inputs: [{ name: '', type: 'uint256', internalType: 'uint256' }, { name: '', type: 'uint8', internalType: 'uint8' }], outputs: [{ name: '', type: 'address', internalType: 'address' }], stateMutability: 'view' },
  { type: 'function', name: 'getAllArtifacts', inputs: [], outputs: [{ name: 'artifacts', type: 'tuple[]', internalType: 'struct ArtifactRegistry.Artifact[]', components: [{ name: 'id', type: 'uint8', internalType: 'uint8' }, { name: 'name', type: 'string', internalType: 'string' }, { name: 'attackBonus', type: 'int8', internalType: 'int8' }, { name: 'defenseBonus', type: 'int8', internalType: 'int8' }, { name: 'hpBonus', type: 'int16', internalType: 'int16' }] }], stateMutability: 'pure' },
  { type: 'function', name: 'getArtifact', inputs: [{ name: 'id', type: 'uint8', internalType: 'uint8' }], outputs: [{ name: 'artifact', type: 'tuple', internalType: 'struct ArtifactRegistry.Artifact', components: [{ name: 'id', type: 'uint8', internalType: 'uint8' }, { name: 'name', type: 'string', internalType: 'string' }, { name: 'attackBonus', type: 'int8', internalType: 'int8' }, { name: 'defenseBonus', type: 'int8', internalType: 'int8' }, { name: 'hpBonus', type: 'int16', internalType: 'int16' }] }], stateMutability: 'pure' },
  { type: 'function', name: 'getPlayerArtifactIds', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }, { name: 'player', type: 'address', internalType: 'address' }], outputs: [{ name: '', type: 'uint8[]', internalType: 'uint8[]' }], stateMutability: 'view' },
  { type: 'function', name: 'getPlayerStats', inputs: [{ name: 'gameId', type: 'uint256', internalType: 'uint256' }, { name: 'player', type: 'address', internalType: 'address' }], outputs: [{ name: 'hp', type: 'int16', internalType: 'int16' }, { name: 'attack', type: 'int8', internalType: 'int8' }, { name: 'defense', type: 'int8', internalType: 'int8' }], stateMutability: 'view' },
  { type: 'function', name: 'playerArtifacts', inputs: [{ name: '', type: 'uint256', internalType: 'uint256' }, { name: '', type: 'address', internalType: 'address' }, { name: '', type: 'uint256', internalType: 'uint256' }], outputs: [{ name: '', type: 'uint8', internalType: 'uint8' }], stateMutability: 'view' },
  { type: 'event', name: 'ArtifactClaimed', inputs: [{ name: 'gameId', type: 'uint256', indexed: true, internalType: 'uint256' }, { name: 'player', type: 'address', indexed: true, internalType: 'address' }, { name: 'artifactId', type: 'uint8', indexed: false, internalType: 'uint8' }, { name: 'treasureCellIndex', type: 'uint8', indexed: false, internalType: 'uint8' }], anonymous: false },
] as const;

// ── Typed contract configs for wagmi hooks ─────────────────

export const shadowChainGameConfig = {
  address: SHADOW_CHAIN_GAME_ADDRESS,
  abi: shadowChainGameAbi,
} as const;

export const artifactRegistryConfig = {
  address: ARTIFACT_REGISTRY_ADDRESS,
  abi: artifactRegistryAbi,
} as const;

// ── GameState enum mapping ─────────────────────────────────

export enum OnChainGameState {
  WaitingForPlayers = 0,
  Active = 1,
  Ended = 2,
}

export function gameStateToStatus(state: number): 'waiting' | 'active' | 'ended' {
  switch (state) {
    case OnChainGameState.WaitingForPlayers: return 'waiting';
    case OnChainGameState.Active: return 'active';
    case OnChainGameState.Ended: return 'ended';
    default: return 'ended';
  }
}
