/**
 * Game state management — reads on-chain data and provides typed game state
 * for the UI components, plus action handlers for contract writes.
 */

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  useReadContract,
  useReadContracts,
  useWriteContract,
  useWaitForTransactionReceipt,
  useWatchContractEvent,
  useAccount,
  usePublicClient,
} from 'wagmi';
import { formatEther, parseEther, type Log } from 'viem';
import {
  shadowChainGameConfig,
  artifactRegistryConfig,
  SHADOW_CHAIN_GAME_ADDRESS,
  shadowChainGameAbi,
  gameStateToStatus,
} from '@/lib/contracts';
import {
  initProver,
  generatePositionCommitProof,
  generateMoveProof,
  generateClaimArtifactProof,
  generateCombatRevealProof,
  computeInventoryCommitment,
  randomSalt,
  proofToHex,
  publicInputsToBytes32,
  isProverReady,
  computePedersenHash,
  toFieldHex,
} from '@/lib/noir-prover';
import type {
  Cell,
  CellType,
  Position,
  Player,
  Artifact,
  GameState,
  CombatEvent,
} from '@/types/game';

// ── Bitmap Parsing ──────────────────────────────────────

/**
 * Parse a uint256 wall bitmap into a 16x16 Cell grid.
 * Note: Treasures are now procedurally generated and not visible in bitmap.
 * Use the contract's isTreasure(gameId, x, y) to check individual cells.
 */
export function parseBitmapsToMap(wallBitmap: bigint): Cell[][] {
  const map: Cell[][] = [];
  for (let y = 0; y < 16; y++) {
    const row: Cell[] = [];
    for (let x = 0; x < 16; x++) {
      const idx = BigInt(y * 16 + x);
      const isWall = (wallBitmap >> idx) & 1n;

      let type: CellType = 'empty';
      if (isWall) type = 'wall';
      // Treasures are procedural - discovered when player steps on them

      row.push({ type, x, y });
    }
    map.push(row);
  }
  return map;
}

/**
 * Convert a wallBitmap into 16 row bitmasks (for the valid_move circuit).
 * Row y has bits for columns 0-15 indicating walls.
 */
export function bitmapToRowBitmasks(wallBitmap: bigint): bigint[] {
  const rows: bigint[] = [];
  for (let y = 0; y < 16; y++) {
    let rowBits = 0n;
    for (let x = 0; x < 16; x++) {
      const idx = BigInt(y * 16 + x);
      if ((wallBitmap >> idx) & 1n) {
        rowBits |= 1n << BigInt(x);
      }
    }
    rows.push(rowBits);
  }
  return rows;
}

/**
 * Get all non-wall cell positions (potential spawn points).
 */
export function getSpawnCandidates(map: Cell[][]): Position[] {
  const candidates: Position[] = [];
  for (let y = 0; y < 16; y++) {
    for (let x = 0; x < 16; x++) {
      if (map[y][x].type !== 'wall') {
        candidates.push({ x, y });
      }
    }
  }
  return candidates;
}

/**
 * Pick a random spawn position from empty cells.
 */
export function pickRandomSpawn(map: Cell[][]): Position {
  const candidates = getSpawnCandidates(map).filter(
    (p) => map[p.y][p.x].type === 'empty'
  );
  if (candidates.length === 0) {
    // Fallback: any non-wall
    const fallback = getSpawnCandidates(map);
    return fallback[Math.floor(Math.random() * fallback.length)] ?? { x: 0, y: 0 };
  }
  return candidates[Math.floor(Math.random() * candidates.length)];
}

// ── Visibility ──────────────────────────────────────────

export function getVisibleCells(playerPos: Position, radius: number = 3): Set<string> {
  const visible = new Set<string>();
  for (let dy = -radius; dy <= radius; dy++) {
    for (let dx = -radius; dx <= radius; dx++) {
      const nx = playerPos.x + dx;
      const ny = playerPos.y + dy;
      if (nx >= 0 && nx < 16 && ny >= 0 && ny < 16) {
        if (Math.sqrt(dx * dx + dy * dy) <= radius) {
          visible.add(`${nx},${ny}`);
        }
      }
    }
  }
  return visible;
}

// ── Private State Persistence ───────────────────────────

interface PrivateGameState {
  position: Position;
  salt: bigint;
  playerSalt: bigint;
  playerSecret: bigint;     // NEW: for nullifier derivation in claim_artifact
  inventorySalt: bigint;    // NEW: for inventory commitment
  artifactIds: number[];    // Owned artifacts (up to 8)
}

function getStorageKey(gameId: string, address: string): string {
  return `shadowchain_game_${gameId}_${address.toLowerCase()}`;
}

function savePrivateState(gameId: string, address: string, state: PrivateGameState): void {
  try {
    const data = {
      position: state.position,
      salt: state.salt.toString(),
      playerSalt: state.playerSalt.toString(),
      playerSecret: state.playerSecret.toString(),
      inventorySalt: state.inventorySalt.toString(),
      artifactIds: state.artifactIds,
    };
    localStorage.setItem(getStorageKey(gameId, address), JSON.stringify(data));
  } catch {
    // localStorage might not be available
  }
}

function loadPrivateState(gameId: string, address: string): PrivateGameState | null {
  try {
    const raw = localStorage.getItem(getStorageKey(gameId, address));
    if (!raw) return null;
    const data = JSON.parse(raw);
    return {
      position: data.position,
      salt: BigInt(data.salt),
      playerSalt: BigInt(data.playerSalt),
      playerSecret: data.playerSecret ? BigInt(data.playerSecret) : randomSalt(),
      inventorySalt: data.inventorySalt ? BigInt(data.inventorySalt) : randomSalt(),
      artifactIds: data.artifactIds || [],
    };
  } catch {
    return null;
  }
}

// ── On-Chain Game Data Hook ─────────────────────────────

interface OnChainGameData {
  id: bigint;
  seed: bigint;
  entryFee: bigint;
  prizePool: bigint;
  wallBitmap: bigint;
  treasureSeed: string;     // CHANGED: procedural treasure seed (bytes32)
  currentTurn: number;
  maxTurns: number;
  maxPlayers: number;
  playerCount: number;
  aliveCount: number;
  turnDeadline: bigint;
  creator: string;
  winner: string;
  state: number;
}

interface OnChainPlayerData {
  addr: string;
  commitment: string;
  hp: number;
  attack: number;
  defense: number;
  status: number; // 0=None, 1=Alive, 2=Dead, 3=Forfeited
  hasSubmittedThisTurn: boolean;
}

export function useGameData(gameId: string) {
  const { address } = useAccount();
  const gameIdBigInt = BigInt(gameId);

  // Read game data
  const {
    data: gameData,
    isLoading: gameLoading,
    error: gameError,
    refetch: refetchGame,
  } = useReadContract({
    ...shadowChainGameConfig,
    functionName: 'getGame',
    args: [gameIdBigInt],
  });

  // Read player addresses
  const playerCount = (gameData as any)?.playerCount ?? 0;
  const playerAddressContracts = useMemo(() => {
    if (!playerCount) return [];
    return Array.from({ length: playerCount }, (_, i) => ({
      ...shadowChainGameConfig,
      functionName: 'playerByIndex' as const,
      args: [gameIdBigInt, i] as const,
    }));
  }, [gameIdBigInt, playerCount]);

  const { data: playerAddresses, refetch: refetchAddresses } = useReadContracts({
    contracts: playerAddressContracts,
    query: { enabled: playerCount > 0 },
  });

  // Read player data for each address
  const addressList = useMemo(() => {
    if (!playerAddresses) return [];
    return playerAddresses
      .filter((r) => r.status === 'success' && r.result)
      .map((r) => r.result as string);
  }, [playerAddresses]);

  const playerDataContracts = useMemo(() => {
    return addressList.map((addr) => ({
      ...shadowChainGameConfig,
      functionName: 'getPlayer' as const,
      args: [gameIdBigInt, addr as `0x${string}`] as const,
    }));
  }, [gameIdBigInt, addressList]);

  const { data: playersData, refetch: refetchPlayers } = useReadContracts({
    contracts: playerDataContracts,
    query: { enabled: addressList.length > 0 },
  });

  // Parse game data
  const game = useMemo((): OnChainGameData | null => {
    if (!gameData) return null;
    const g = gameData as any;
    return {
      id: g.id,
      seed: g.seed,
      entryFee: g.entryFee,
      prizePool: g.prizePool,
      wallBitmap: g.wallBitmap,
      treasureSeed: g.treasureSeed,  // Procedural treasure seed
      currentTurn: Number(g.currentTurn),
      maxTurns: Number(g.maxTurns),
      maxPlayers: Number(g.maxPlayers),
      playerCount: Number(g.playerCount),
      aliveCount: Number(g.aliveCount),
      turnDeadline: g.turnDeadline,
      creator: g.creator,
      winner: g.winner,
      state: Number(g.state),
    };
  }, [gameData]);

  // Parse players
  const players = useMemo((): OnChainPlayerData[] => {
    if (!playersData) return [];
    return playersData
      .filter((r) => r.status === 'success' && r.result)
      .map((r) => {
        const p = r.result as any;
        return {
          addr: p.addr,
          commitment: p.commitment,
          hp: Number(p.hp),
          attack: Number(p.attack),
          defense: Number(p.defense),
          status: Number(p.status),
          hasSubmittedThisTurn: p.hasSubmittedThisTurn,
        };
      });
  }, [playersData]);

  // Parse map (treasures are procedural, not in bitmap)
  const map = useMemo((): Cell[][] => {
    if (!game) return emptyMap();
    return parseBitmapsToMap(game.wallBitmap);
  }, [game]);

  // Wall bitmasks for circuits
  const mapWalls = useMemo((): bigint[] => {
    if (!game) return new Array(16).fill(0n);
    return bitmapToRowBitmasks(game.wallBitmap);
  }, [game]);

  // Refetch all data
  const refetch = useCallback(() => {
    refetchGame();
    refetchAddresses();
    refetchPlayers();
  }, [refetchGame, refetchAddresses, refetchPlayers]);

  // Time remaining calculation
  const timeRemaining = useMemo(() => {
    if (!game || !game.turnDeadline) return 0;
    const deadline = Number(game.turnDeadline);
    if (deadline === 0) return 0;
    const now = Math.floor(Date.now() / 1000);
    return Math.max(0, deadline - now);
  }, [game]);

  // Convert to GameState format for components
  const gameState = useMemo((): GameState | null => {
    if (!game) return null;

    const uiPlayers: Player[] = players.map((p) => ({
      address: p.addr,
      hp: Math.max(0, p.hp),
      maxHp: 100, // BASE_HP
      attack: p.attack,
      defense: p.defense,
      artifacts: [], // We'll fill these separately if needed
      isAlive: p.status === 1, // 1 = Alive
      score: 0,
    }));

    return {
      id: gameId,
      turn: game.currentTurn,
      maxTurns: game.maxTurns,
      timeRemaining,
      phase: gameStateToStatus(game.state),
      players: uiPlayers,
      map,
      currentPlayer: address ?? '',
      events: [],
      pot: formatEther(game.prizePool),
      entryFee: formatEther(game.entryFee),
      maxPlayers: game.maxPlayers,
      winner: game.winner === '0x0000000000000000000000000000000000000000' ? undefined : game.winner,
    };
  }, [game, players, map, address, gameId, timeRemaining]);

  return {
    game,
    players,
    map,
    mapWalls,
    gameState,
    isLoading: gameLoading,
    error: gameError,
    refetch,
    address,
  };
}

// ── Game Actions Hook ───────────────────────────────────

export function useGameActions(gameId: string) {
  const { address } = useAccount();
  const {
    writeContract,
    data: txHash,
    isPending: isWriting,
    error: writeError,
    reset: resetWrite,
  } = useWriteContract();

  const {
    isLoading: isConfirming,
    isSuccess: isConfirmed,
    error: confirmError,
  } = useWaitForTransactionReceipt({ hash: txHash });

  const gameIdBigInt = BigInt(gameId);

  // ── Join Game ──────────────────────────────────
  const joinGame = useCallback(
    async (commitment: `0x${string}`, inventoryCommitment: `0x${string}`, entryFee: bigint) => {
      writeContract({
        ...shadowChainGameConfig,
        functionName: 'joinGame',
        args: [gameIdBigInt, commitment, inventoryCommitment],
        value: entryFee,
      });
    },
    [writeContract, gameIdBigInt]
  );

  // ── Submit Move ────────────────────────────────
  const submitMove = useCallback(
    (
      newCommitment: `0x${string}`,
      proof: `0x${string}`,
      publicInputs: `0x${string}`[]
    ) => {
      writeContract({
        ...shadowChainGameConfig,
        functionName: 'submitMove',
        args: [gameIdBigInt, newCommitment, proof, publicInputs],
      });
    },
    [writeContract, gameIdBigInt]
  );

  // ── Claim Artifact ─────────────────────────────
  const claimArtifact = useCallback(
    (
      cellX: number,
      cellY: number,
      proof: `0x${string}`,
      publicInputs: `0x${string}`[],
      newInventoryCommitment: `0x${string}`
    ) => {
      writeContract({
        ...shadowChainGameConfig,
        functionName: 'claimArtifact',
        args: [gameIdBigInt, cellX, cellY, proof, publicInputs, newInventoryCommitment],
      });
    },
    [writeContract, gameIdBigInt]
  );

  // ── Trigger Combat ─────────────────────────────
  const triggerCombat = useCallback(
    (
      defender: `0x${string}`,
      proof: `0x${string}`,
      publicInputs: `0x${string}`[]
    ) => {
      writeContract({
        ...shadowChainGameConfig,
        functionName: 'triggerCombat',
        args: [gameIdBigInt, defender, proof, publicInputs],
      });
    },
    [writeContract, gameIdBigInt]
  );

  // ── Advance Turn ───────────────────────────────
  const advanceTurn = useCallback(() => {
    writeContract({
      ...shadowChainGameConfig,
      functionName: 'advanceTurn',
      args: [gameIdBigInt],
    });
  }, [writeContract, gameIdBigInt]);

  // ── Start Game ─────────────────────────────────
  const startGame = useCallback(() => {
    writeContract({
      ...shadowChainGameConfig,
      functionName: 'startGame',
      args: [gameIdBigInt],
    });
  }, [writeContract, gameIdBigInt]);

  // ── Forfeit ────────────────────────────────────
  const forfeit = useCallback(() => {
    writeContract({
      ...shadowChainGameConfig,
      functionName: 'forfeit',
      args: [gameIdBigInt],
    });
  }, [writeContract, gameIdBigInt]);

  return {
    joinGame,
    submitMove,
    claimArtifact,
    triggerCombat,
    advanceTurn,
    startGame,
    forfeit,
    txHash,
    isWriting,
    isConfirming,
    isConfirmed,
    writeError,
    confirmError,
    resetWrite,
  };
}

// ── Event Watching Hook ─────────────────────────────────

export function useGameEvents(
  gameId: string,
  onEvent: (event: CombatEvent) => void
) {
  const gameIdBigInt = BigInt(gameId);

  // Watch MoveSubmitted
  useWatchContractEvent({
    ...shadowChainGameConfig,
    eventName: 'MoveSubmitted',
    args: { gameId: gameIdBigInt },
    onLogs(logs) {
      for (const log of logs) {
        const args = (log as any).args;
        onEvent({
          id: `move-${log.transactionHash}-${log.logIndex}`,
          timestamp: Date.now(),
          type: 'move',
          message: `${truncAddr(args.player)} submitted move (turn ${args.turn})`,
          players: [args.player],
        });
      }
    },
  });

  // Watch ArtifactClaimedEvent
  useWatchContractEvent({
    ...shadowChainGameConfig,
    eventName: 'ArtifactClaimedEvent',
    args: { gameId: gameIdBigInt },
    onLogs(logs) {
      for (const log of logs) {
        const args = (log as any).args;
        onEvent({
          id: `artifact-${log.transactionHash}-${log.logIndex}`,
          timestamp: Date.now(),
          type: 'artifact',
          message: `${truncAddr(args.player)} claimed artifact #${args.artifactId} at cell ${args.cellIndex}`,
          players: [args.player],
        });
      }
    },
  });

  // Watch CombatTriggered
  useWatchContractEvent({
    ...shadowChainGameConfig,
    eventName: 'CombatTriggered',
    args: { gameId: gameIdBigInt },
    onLogs(logs) {
      for (const log of logs) {
        const args = (log as any).args;
        onEvent({
          id: `combat-${log.transactionHash}-${log.logIndex}`,
          timestamp: Date.now(),
          type: 'combat',
          message: `${truncAddr(args.attacker)} attacked ${truncAddr(args.defender)} for ${args.damage} damage${args.defenderEliminated ? ' — ELIMINATED!' : ''}`,
          players: [args.attacker, args.defender],
        });
      }
    },
  });

  // Watch TurnAdvanced
  useWatchContractEvent({
    ...shadowChainGameConfig,
    eventName: 'TurnAdvanced',
    args: { gameId: gameIdBigInt },
    onLogs(logs) {
      for (const log of logs) {
        const args = (log as any).args;
        onEvent({
          id: `turn-${log.transactionHash}-${log.logIndex}`,
          timestamp: Date.now(),
          type: 'system',
          message: `Turn ${args.newTurn} begins`,
        });
      }
    },
  });

  // Watch PlayerJoined
  useWatchContractEvent({
    ...shadowChainGameConfig,
    eventName: 'PlayerJoined',
    args: { gameId: gameIdBigInt },
    onLogs(logs) {
      for (const log of logs) {
        const args = (log as any).args;
        onEvent({
          id: `join-${log.transactionHash}-${log.logIndex}`,
          timestamp: Date.now(),
          type: 'system',
          message: `${truncAddr(args.player)} joined the game`,
          players: [args.player],
        });
      }
    },
  });

  // Watch PlayerEliminated
  useWatchContractEvent({
    ...shadowChainGameConfig,
    eventName: 'PlayerEliminated',
    args: { gameId: gameIdBigInt },
    onLogs(logs) {
      for (const log of logs) {
        const args = (log as any).args;
        onEvent({
          id: `death-${log.transactionHash}-${log.logIndex}`,
          timestamp: Date.now(),
          type: 'death',
          message: `${truncAddr(args.player)} has been eliminated`,
          players: [args.player],
        });
      }
    },
  });

  // Watch GameResolved
  useWatchContractEvent({
    ...shadowChainGameConfig,
    eventName: 'GameResolved',
    args: { gameId: gameIdBigInt },
    onLogs(logs) {
      for (const log of logs) {
        const args = (log as any).args;
        onEvent({
          id: `resolved-${log.transactionHash}-${log.logIndex}`,
          timestamp: Date.now(),
          type: 'system',
          message: `Game resolved! Winner: ${truncAddr(args.winner)} — Prize: ${formatEther(args.prize)} ETH`,
          players: [args.winner],
        });
      }
    },
  });
}

// ── Helpers ─────────────────────────────────────────────

function emptyMap(): Cell[][] {
  const map: Cell[][] = [];
  for (let y = 0; y < 16; y++) {
    const row: Cell[] = [];
    for (let x = 0; x < 16; x++) {
      row.push({ type: 'empty', x, y });
    }
    map.push(row);
  }
  return map;
}

function truncAddr(address: string): string {
  if (!address) return '';
  return `${address.slice(0, 6)}…${address.slice(-4)}`;
}

// Re-export for convenience
export { savePrivateState, loadPrivateState };
export type { PrivateGameState, OnChainGameData, OnChainPlayerData };
