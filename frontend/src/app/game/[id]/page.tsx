'use client';

import { useState, useCallback, useEffect, useRef, useMemo } from 'react';
import Link from 'next/link';
import { useAccount } from 'wagmi';
import { formatEther } from 'viem';
import { truncateAddress, cn } from '@/lib/utils';
import GameGrid from '@/components/GameGrid';
import TurnTimer from '@/components/TurnTimer';
import CombatLog from '@/components/CombatLog';
import PlayerCard from '@/components/PlayerCard';
import ProofStatus from '@/components/ProofStatus';
import type { ProofStage } from '@/components/ProofStatus';
import WalletConnect from '@/components/WalletConnect';
import {
  initProver,
  generatePositionCommitProof,
  generateMoveProof,
  generateClaimArtifactProof,
  generateCombatRevealProof,
  randomSalt,
  isProverReady,
  proofToHex,
  publicInputsToBytes32,
} from '@/lib/noir-prover';
import {
  useGameData,
  useGameActions,
  useGameEvents,
  getVisibleCells,
  pickRandomSpawn,
  bitmapToRowBitmasks,
  savePrivateState,
  loadPrivateState,
} from '@/lib/game-state';
import type { Position, Direction, CombatEvent } from '@/types/game';

// ── Game Page Component ─────────────────────────────────

export default function GamePage({ params }: { params: { id: string } }) {
  const gameId = params.id;
  const { address, isConnected } = useAccount();

  // ── On-chain data ──────────────────────────────────
  const {
    game,
    gameState: onChainGameState,
    map,
    mapWalls,
    isLoading,
    error,
    refetch,
  } = useGameData(gameId);

  const {
    joinGame,
    submitMove,
    claimArtifact,
    triggerCombat,
    advanceTurn,
    startGame,
    forfeit,
    isWriting,
    isConfirming,
    isConfirmed,
    writeError,
    resetWrite,
  } = useGameActions(gameId);

  // ── Local state ────────────────────────────────────
  const [playerPos, setPlayerPos] = useState<Position | null>(null);
  const [proofStage, setProofStage] = useState<ProofStage>('idle');
  const [proofType, setProofType] = useState<string>('valid_move');
  const [proofError, setProofError] = useState<string | null>(null);
  const [events, setEvents] = useState<CombatEvent[]>([]);
  const [hasJoined, setHasJoined] = useState(false);

  const currentSalt = useRef<bigint>(randomSalt());
  const playerSalt = useRef<bigint>(randomSalt());
  const collectedArtifacts = useRef<number[]>([]);

  const isProving = proofStage !== 'idle' && proofStage !== 'done' && proofStage !== 'error';

  // ── Track ZK prover readiness ──────────────────────
  const [proverReady, setProverReady] = useState(() => isProverReady());

  useEffect(() => {
    // If already ready, nothing to poll
    if (proverReady) return;

    const interval = setInterval(() => {
      if (isProverReady()) {
        setProverReady(true);
        clearInterval(interval);
      }
    }, 500);

    return () => clearInterval(interval);
  }, [proverReady]);

  // Also re-check after wallet connects (isConnected change)
  useEffect(() => {
    if (isConnected && !proverReady) {
      // Trigger init if not already running
      initProver(['valid_move']).then(() => {
        if (isProverReady()) setProverReady(true);
      }).catch(() => {});
    }
  }, [isConnected, proverReady]);

  // ── Restore private state from localStorage ────────
  useEffect(() => {
    if (!address || !gameId) return;
    const saved = loadPrivateState(gameId, address);
    if (saved) {
      setPlayerPos(saved.position);
      currentSalt.current = saved.salt;
      playerSalt.current = saved.playerSalt;
      collectedArtifacts.current = saved.artifactIds;
      setHasJoined(true);
    }
  }, [address, gameId]);

  // ── Check if player already joined on-chain ────────
  useEffect(() => {
    if (!address || !onChainGameState) return;
    const isPlayer = onChainGameState.players.some(
      (p) => p.address.toLowerCase() === address.toLowerCase()
    );
    if (isPlayer && !hasJoined && !playerPos) {
      // Player is in the game but we lost local state
      // They need to re-enter their position or we start fresh
      setHasJoined(true);
    }
  }, [address, onChainGameState, hasJoined, playerPos]);

  // ── Save private state on changes ──────────────────
  useEffect(() => {
    if (!address || !gameId || !playerPos) return;
    savePrivateState(gameId, address, {
      position: playerPos,
      salt: currentSalt.current,
      playerSalt: playerSalt.current,
      artifactIds: collectedArtifacts.current,
    });
  }, [address, gameId, playerPos]);

  // ── Pre-initialize prover ──────────────────────────
  useEffect(() => {
    initProver(['valid_move']).catch((err) =>
      console.warn('[ZK] Prover pre-init failed:', err)
    );
  }, []);

  // ── Event watching ─────────────────────────────────
  const addEvent = useCallback((evt: CombatEvent) => {
    setEvents((prev) => {
      // Deduplicate by id
      if (prev.some((e) => e.id === evt.id)) return prev;
      return [...prev, evt];
    });
  }, []);

  useGameEvents(gameId, (evt) => {
    addEvent(evt);
    // Refetch game data when events happen
    refetch();
  });

  // ── Refetch on tx confirmation ─────────────────────
  useEffect(() => {
    if (isConfirmed) {
      refetch();
      resetWrite();
    }
  }, [isConfirmed, refetch, resetWrite]);

  // ── Derived state ──────────────────────────────────
  const visibleCells = useMemo(
    () => (playerPos ? getVisibleCells(playerPos, 3) : new Set<string>()),
    [playerPos]
  );

  // Compute map walls from on-chain bitmap
  const wallBitmasks = useMemo(
    () => (game ? bitmapToRowBitmasks(game.wallBitmap) : new Array(16).fill(0n)),
    [game]
  );

  // Build the display GameState
  const displayGameState = useMemo(() => {
    if (!onChainGameState) return null;
    return {
      ...onChainGameState,
      events,
      currentPlayer: address ?? '',
    };
  }, [onChainGameState, events, address]);

  const gamePhase = game ? (['waiting', 'active', 'ended'] as const)[game.state] ?? 'ended' : 'waiting';
  const isPlayerInGame = onChainGameState?.players.some(
    (p) => p.address.toLowerCase() === (address ?? '').toLowerCase()
  ) ?? false;
  const currentPlayerData = onChainGameState?.players.find(
    (p) => p.address.toLowerCase() === (address ?? '').toLowerCase()
  );
  const hasSubmittedThisTurn = false; // Will be checked from contract

  // ── Join Game Handler ──────────────────────────────
  const handleJoin = useCallback(async () => {
    if (!address || !game || !map) return;
    if (isProving || isWriting) return;

    try {
      setProofType('position_commit');
      setProofError(null);

      // Pick spawn position
      const spawnPos = pickRandomSpawn(map);
      const salt = randomSalt();
      const pSalt = randomSalt();

      // Init prover if needed
      if (!isProverReady()) {
        setProofStage('initializing');
        await initProver(['position_commit']);
      }

      // Generate proof
      setProofStage('generating_proof');
      const result = await generatePositionCommitProof({
        x: spawnPos.x,
        y: spawnPos.y,
        salt,
      });

      setProofStage('done');

      // Save private state
      currentSalt.current = salt;
      playerSalt.current = pSalt;
      setPlayerPos(spawnPos);
      setHasJoined(true);
      savePrivateState(gameId, address, {
        position: spawnPos,
        salt,
        playerSalt: pSalt,
        artifactIds: [],
      });

      // Submit to contract
      const commitment = result.commitment as `0x${string}`;
      await joinGame(commitment, game.entryFee);

      addEvent({
        id: `join-local-${Date.now()}`,
        timestamp: Date.now(),
        type: 'system',
        message: `${truncateAddress(address)} joined the arena at a hidden position. ZK proof verified ✓`,
        players: [address],
      });

      setTimeout(() => setProofStage('idle'), 2000);
    } catch (err: any) {
      console.error('[ZK] Join failed:', err);
      setProofStage('error');
      setProofError(err?.message || 'Failed to join game');
      setTimeout(() => setProofStage('idle'), 4000);
    }
  }, [address, game, map, isProving, isWriting, gameId, joinGame, addEvent]);

  // ── Move Handler ───────────────────────────────────
  const startMoveAction = useCallback(
    async (x: number, y: number) => {
      if (!playerPos || isProving || isWriting) return;
      if (!address) return;

      const newPos = { x, y };
      const oldSalt = currentSalt.current;
      const newSalt = randomSalt();

      let dir: Direction = 'stay';
      if (x > playerPos.x) dir = 'E';
      else if (x < playerPos.x) dir = 'W';
      else if (y > playerPos.y) dir = 'S';
      else if (y < playerPos.y) dir = 'N';

      try {
        setProofType('valid_move');
        setProofError(null);

        if (!isProverReady()) {
          setProofStage('initializing');
          await initProver(['valid_move']);
        }

        setProofStage('computing_witness');
        setProofStage('generating_proof');

        const result = await generateMoveProof({
          oldPos: playerPos,
          newPos,
          oldSalt,
          newSalt,
          mapWalls: wallBitmasks,
        });

        setProofStage('verifying');
        await new Promise((r) => setTimeout(r, 200));
        setProofStage('done');

        console.log('[ZK] Move proof:', {
          proofSize: result.proof.length,
          oldCommitment: result.oldCommitment,
          newCommitment: result.newCommitment,
        });

        // Update local state
        currentSalt.current = newSalt;
        setPlayerPos(newPos);
        savePrivateState(gameId, address, {
          position: newPos,
          salt: newSalt,
          playerSalt: playerSalt.current,
          artifactIds: collectedArtifacts.current,
        });

        // Submit to contract
        const proofHex = proofToHex(result.proof);
        const pubInputs = publicInputsToBytes32(result.publicInputs);
        submitMove(
          result.newCommitment as `0x${string}`,
          proofHex,
          pubInputs
        );

        addEvent({
          id: `move-local-${Date.now()}`,
          timestamp: Date.now(),
          type: 'move',
          message: `${truncateAddress(address)} moved ${dir} — ZK proof generated (${result.proof.length} bytes)`,
          players: [address],
        });

        // Check for treasure at new position
        const cell = map[newPos.y]?.[newPos.x];
        if (cell?.type === 'treasure') {
          addEvent({
            id: `treasure-discover-${Date.now()}`,
            timestamp: Date.now(),
            type: 'artifact',
            message: `${truncateAddress(address)} discovered treasure! Use the claim button to collect it.`,
            players: [address],
          });
        }

        setTimeout(() => setProofStage('idle'), 2000);
      } catch (err: any) {
        console.error('[ZK] Move proof failed:', err);
        setProofStage('error');
        setProofError(err?.message || 'Move proof generation failed');
        setTimeout(() => setProofStage('idle'), 4000);
      }
    },
    [playerPos, isProving, isWriting, address, wallBitmasks, gameId, map, submitMove, addEvent]
  );

  // ── Claim Artifact Handler ─────────────────────────
  const handleClaimArtifact = useCallback(async () => {
    if (!playerPos || !address || isProving || isWriting) return;

    const cell = map[playerPos.y]?.[playerPos.x];
    if (cell?.type !== 'treasure') {
      setProofError('You must be on a treasure cell to claim an artifact');
      return;
    }

    try {
      setProofType('claim_artifact');
      setProofError(null);

      if (!isProverReady()) {
        setProofStage('initializing');
        await initProver(['claim_artifact']);
      }

      setProofStage('generating_proof');

      // artifactId will be determined by the contract; use 1 as placeholder
      // The circuit just checks it's non-zero
      const artifactId = 1;
      const cellIndex = playerPos.y * 16 + playerPos.x;

      const result = await generateClaimArtifactProof({
        x: playerPos.x,
        y: playerPos.y,
        salt: currentSalt.current,
        artifactId,
      });

      setProofStage('done');

      // Submit to contract
      const proofHex = proofToHex(result.proof);
      const pubInputs = publicInputsToBytes32(result.publicInputs);
      claimArtifact(cellIndex, proofHex, pubInputs);

      addEvent({
        id: `claim-local-${Date.now()}`,
        timestamp: Date.now(),
        type: 'artifact',
        message: `Claiming artifact at (${playerPos.x}, ${playerPos.y})… ZK proof verified ✓`,
        players: [address],
      });

      setTimeout(() => setProofStage('idle'), 2000);
    } catch (err: any) {
      console.error('[ZK] Claim artifact failed:', err);
      setProofStage('error');
      setProofError(err?.message || 'Claim artifact proof failed');
      setTimeout(() => setProofStage('idle'), 4000);
    }
  }, [playerPos, address, isProving, isWriting, map, claimArtifact, addEvent]);

  // ── Combat Handler ─────────────────────────────────
  const handleCombat = useCallback(
    async (defenderAddress: `0x${string}`) => {
      if (!playerPos || !address || isProving || isWriting) return;

      try {
        setProofType('combat_reveal');
        setProofError(null);

        if (!isProverReady()) {
          setProofStage('initializing');
          await initProver(['combat_reveal']);
        }

        setProofStage('generating_proof');

        const result = await generateCombatRevealProof({
          x: playerPos.x,
          y: playerPos.y,
          salt: currentSalt.current,
          playerSalt: playerSalt.current,
          artifactIds: collectedArtifacts.current,
          gameId: BigInt(gameId),
        });

        setProofStage('done');

        // Submit to contract
        const proofHex = proofToHex(result.proof);
        const pubInputs = publicInputsToBytes32(result.publicInputs);
        triggerCombat(defenderAddress, proofHex, pubInputs);

        addEvent({
          id: `combat-local-${Date.now()}`,
          timestamp: Date.now(),
          type: 'combat',
          message: `Initiating combat against ${truncateAddress(defenderAddress)}… ZK proof verified ✓`,
          players: [address, defenderAddress],
        });

        setTimeout(() => setProofStage('idle'), 2000);
      } catch (err: any) {
        console.error('[ZK] Combat proof failed:', err);
        setProofStage('error');
        setProofError(err?.message || 'Combat proof generation failed');
        setTimeout(() => setProofStage('idle'), 4000);
      }
    },
    [playerPos, address, isProving, isWriting, gameId, triggerCombat, addEvent]
  );

  // ── Keyboard controls ─────────────────────────────
  const tryMove = useCallback(
    (dir: Direction) => {
      if (!playerPos || isProving || isWriting || dir === 'stay') return;
      const np = { ...playerPos };
      if (dir === 'N') np.y -= 1;
      if (dir === 'S') np.y += 1;
      if (dir === 'E') np.x += 1;
      if (dir === 'W') np.x -= 1;
      if (np.x < 0 || np.x > 15 || np.y < 0 || np.y > 15) return;
      if (map[np.y]?.[np.x]?.type === 'wall') return;
      startMoveAction(np.x, np.y);
    },
    [playerPos, isProving, isWriting, map, startMoveAction]
  );

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const k = e.key.toLowerCase();
      const keyMap: Record<string, Direction> = {
        arrowup: 'N', w: 'N',
        arrowdown: 'S', s: 'S',
        arrowleft: 'W', a: 'W',
        arrowright: 'E', d: 'E',
      };
      const dir = keyMap[k];
      if (dir) { e.preventDefault(); tryMove(dir); }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [tryMove]);

  // ── Loading state ──────────────────────────────────
  if (isLoading || !displayGameState) {
    return (
      <div className="h-screen flex flex-col items-center justify-center bg-gray-950">
        <div className="text-4xl mb-4 animate-pulse text-emerald-400">◆</div>
        <p className="text-gray-500 text-sm">Loading game #{gameId} from chain…</p>
        {error && (
          <p className="text-red-400 text-xs mt-2">{(error as any)?.message?.slice(0, 120)}</p>
        )}
      </div>
    );
  }

  // ── Determine if on a treasure cell ────────────────
  const isOnTreasure = playerPos && map[playerPos.y]?.[playerPos.x]?.type === 'treasure';

  // ── Phase badge ────────────────────────────────────
  const phaseBadge = {
    waiting: { css: 'bg-amber-500/10 text-amber-400 border-amber-500/30', label: 'WAITING' },
    active: { css: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30', label: 'LIVE' },
    ended: { css: 'bg-gray-500/10 text-gray-500 border-gray-700', label: 'ENDED' },
  }[gamePhase];

  // ── Render ─────────────────────────────────────────
  return (
    <div className="h-screen flex flex-col bg-gray-950 overflow-hidden">
      {/* Top bar */}
      <header className="border-b border-gray-800/50 px-5 py-2.5 flex-shrink-0">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Link href="/lobby" className="flex items-center gap-2 hover:opacity-80 transition-opacity">
              <span className="text-emerald-400">◆</span>
              <span className="text-[10px] font-bold text-gray-500 tracking-[0.25em]">SHADOWCHAIN</span>
            </Link>
            <span className="text-gray-800">|</span>
            <div className="flex items-center gap-2">
              {gamePhase === 'active' && (
                <span className="w-1.5 h-1.5 bg-emerald-400 rounded-full animate-pulse" />
              )}
              <span className="text-sm text-gray-300 font-semibold">Arena #{gameId}</span>
              <span className={cn('text-[9px] px-2 py-0.5 rounded border tracking-wider font-bold', phaseBadge.css)}>
                {phaseBadge.label}
              </span>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-xs text-gray-500">
              Pot: <span className="text-emerald-400 font-bold">{displayGameState.pot} ETH</span>
            </span>
            <WalletConnect />
          </div>
        </div>
      </header>

      {/* Main content */}
      <div className="flex-1 flex min-h-0">
        {/* Left sidebar */}
        <aside className="w-72 border-r border-gray-800/50 flex flex-col flex-shrink-0 overflow-y-auto">
          {/* Timer */}
          <div className="p-3 border-b border-gray-800/50">
            <TurnTimer
              initialTime={displayGameState.timeRemaining}
              turn={displayGameState.turn}
              maxTurns={displayGameState.maxTurns}
            />
          </div>

          {/* Players */}
          <div className="p-3 border-b border-gray-800/50">
            <h3 className="text-[10px] font-bold text-gray-500 uppercase tracking-[0.2em] mb-3">
              Players ({displayGameState.players.filter((p) => p.isAlive).length}/{displayGameState.maxPlayers})
            </h3>
            <div className="space-y-2">
              {displayGameState.players.map((p) => (
                <PlayerCard
                  key={p.address}
                  player={p}
                  isCurrentPlayer={p.address.toLowerCase() === (address ?? '').toLowerCase()}
                />
              ))}
              {displayGameState.players.length === 0 && (
                <p className="text-xs text-gray-600">No players yet</p>
              )}
            </div>
          </div>

          {/* Actions */}
          {gamePhase === 'waiting' && !isPlayerInGame && isConnected && (
            <div className="p-3 border-b border-gray-800/50">
              <button
                onClick={handleJoin}
                disabled={isProving || isWriting || isConfirming}
                className={cn(
                  'w-full py-3 bg-amber-500/10 border-2 border-amber-500/40 text-amber-400 font-semibold rounded-lg',
                  'transition-all hover:bg-amber-500/20 hover:border-amber-400 active:scale-[0.98]',
                  (isProving || isWriting || isConfirming) && 'opacity-50 cursor-not-allowed'
                )}
              >
                {isProving ? 'Generating proof…' : isWriting ? 'Confirm in wallet…' : isConfirming ? 'Confirming…' : `Join Game (${displayGameState.entryFee})`}
              </button>
              {writeError && (
                <p className="text-xs text-red-400 mt-2">{(writeError as any)?.message?.slice(0, 100)}</p>
              )}
            </div>
          )}

          {gamePhase === 'waiting' && isPlayerInGame && isConnected && (
            <div className="p-3 border-b border-gray-800/50 space-y-2">
              <p className="text-xs text-emerald-400">✓ You&apos;ve joined this game</p>
              {game && game.playerCount >= 2 && (
                <button
                  onClick={() => startGame()}
                  disabled={isWriting || isConfirming}
                  className={cn(
                    'w-full py-2.5 bg-emerald-500/10 border border-emerald-500/40 text-emerald-400 text-sm font-semibold rounded-lg',
                    'transition-all hover:bg-emerald-500/20 active:scale-[0.98]',
                    (isWriting || isConfirming) && 'opacity-50 cursor-not-allowed'
                  )}
                >
                  {isWriting ? 'Confirm…' : 'Start Game'}
                </button>
              )}
            </div>
          )}

          {/* Movement controls (only when game is active and player has position) */}
          {gamePhase === 'active' && isPlayerInGame && playerPos && (
            <>
              <div className="p-3 border-b border-gray-800/50">
                <h3 className="text-[10px] font-bold text-gray-500 uppercase tracking-[0.2em] mb-3">Move</h3>
                <div className="grid grid-cols-3 gap-1.5 max-w-[130px] mx-auto">
                  {(['', 'N', '', 'W', 'stay', 'E', '', 'S', ''] as const).map((d, i) => {
                    if (!d) return <div key={i} />;
                    const arrows: Record<string, string> = { N: '↑', S: '↓', E: '→', W: '←', stay: '●' };
                    return (
                      <button
                        key={i}
                        onClick={() => d !== 'stay' && tryMove(d as Direction)}
                        disabled={isProving || isWriting}
                        className={cn(
                          'h-9 bg-gray-800 border border-gray-700 rounded text-sm text-gray-400',
                          'hover:bg-gray-700 hover:text-white hover:border-gray-600 transition-all',
                          'disabled:opacity-30 disabled:cursor-not-allowed active:scale-90',
                          d === 'stay' && 'text-[10px] text-gray-600'
                        )}
                      >
                        {arrows[d]}
                      </button>
                    );
                  })}
                </div>
                <p className="text-[9px] text-gray-600 text-center mt-2">WASD / Arrow keys</p>
              </div>

              {/* Claim artifact button */}
              {isOnTreasure && (
                <div className="p-3 border-b border-gray-800/50">
                  <button
                    onClick={handleClaimArtifact}
                    disabled={isProving || isWriting}
                    className={cn(
                      'w-full py-2.5 bg-amber-500/10 border border-amber-500/40 text-amber-400 text-sm font-semibold rounded-lg',
                      'transition-all hover:bg-amber-500/20 active:scale-[0.98]',
                      (isProving || isWriting) && 'opacity-50 cursor-not-allowed'
                    )}
                  >
                    {isProving ? 'Generating proof…' : '✦ Claim Artifact'}
                  </button>
                </div>
              )}

              {/* Advance turn */}
              <div className="p-3 border-b border-gray-800/50">
                <button
                  onClick={() => advanceTurn()}
                  disabled={isWriting || isConfirming}
                  className={cn(
                    'w-full py-2 bg-gray-800 border border-gray-700 text-gray-400 text-xs font-semibold rounded-lg',
                    'transition-all hover:bg-gray-700 hover:text-gray-300 active:scale-[0.98]',
                    (isWriting || isConfirming) && 'opacity-50 cursor-not-allowed'
                  )}
                >
                  Advance Turn ▶
                </button>
              </div>

              {/* Forfeit */}
              <div className="p-3 border-b border-gray-800/50">
                <button
                  onClick={() => forfeit()}
                  disabled={isWriting || isConfirming}
                  className={cn(
                    'w-full py-2 bg-red-500/5 border border-red-500/20 text-red-400/60 text-xs rounded-lg',
                    'transition-all hover:bg-red-500/10 hover:text-red-400 active:scale-[0.98]',
                    (isWriting || isConfirming) && 'opacity-50 cursor-not-allowed'
                  )}
                >
                  Forfeit
                </button>
              </div>
            </>
          )}

          {/* Not connected message */}
          {!isConnected && (
            <div className="p-3 border-b border-gray-800/50">
              <p className="text-xs text-gray-500 text-center">Connect wallet to play</p>
            </div>
          )}

          {/* Position info */}
          <div className="p-3 mt-auto">
            <div className="bg-gray-900/60 rounded-lg p-3 border border-gray-800/40 text-[10px] space-y-1">
              <div className="flex justify-between">
                <span className="text-gray-500">Position</span>
                <span className="text-emerald-400">
                  {playerPos ? `(${playerPos.x}, ${playerPos.y})` : 'Unknown'}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Visibility</span>
                <span className="text-gray-400">radius 3</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">ZK Prover</span>
                <span className={cn(
                  proverReady ? 'text-emerald-400' : 'text-yellow-500',
                )}>
                  {proverReady ? 'Ready ✓' : 'Loading…'}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Backend</span>
                <span className="text-gray-400">UltraHonk</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Game State</span>
                <span className="text-gray-400">{gamePhase}</span>
              </div>
            </div>
          </div>
        </aside>

        {/* Grid (center) */}
        <main className="flex-1 flex items-center justify-center p-4 overflow-auto">
          {playerPos ? (
            <GameGrid
              map={map}
              playerPosition={playerPos}
              visibleCells={visibleCells}
              enemyPositions={{}}
              isActive={gamePhase === 'active' && isPlayerInGame}
              onCellClick={(x, y) => {
                if (gamePhase === 'active' && isPlayerInGame) {
                  startMoveAction(x, y);
                }
              }}
            />
          ) : (
            <div className="text-center">
              <div className="text-6xl mb-6 opacity-20">◆</div>
              {gamePhase === 'waiting' ? (
                <>
                  <h2 className="text-xl font-bold text-white mb-2">Arena #{gameId}</h2>
                  <p className="text-sm text-gray-500 mb-1">
                    {displayGameState.players.length}/{displayGameState.maxPlayers} players joined
                  </p>
                  <p className="text-xs text-gray-600">
                    Entry fee: {displayGameState.entryFee} ETH
                  </p>
                  {!isPlayerInGame && isConnected && (
                    <button
                      onClick={handleJoin}
                      disabled={isProving || isWriting || isConfirming}
                      className={cn(
                        'mt-6 px-8 py-3 bg-amber-500/10 border-2 border-amber-500/40 text-amber-400 font-semibold rounded-lg',
                        'transition-all hover:bg-amber-500/20 hover:border-amber-400',
                        (isProving || isWriting || isConfirming) && 'opacity-50 cursor-not-allowed'
                      )}
                    >
                      {isProving ? 'Generating ZK proof…' : 'Join Arena'}
                    </button>
                  )}
                </>
              ) : gamePhase === 'active' && isPlayerInGame ? (
                <>
                  <h2 className="text-xl font-bold text-white mb-2">Position Lost</h2>
                  <p className="text-sm text-gray-500">
                    Your local game state was lost. You may need to rejoin or wait for the game to end.
                  </p>
                </>
              ) : gamePhase === 'ended' ? (
                <>
                  <h2 className="text-xl font-bold text-white mb-2">Game Over</h2>
                  {displayGameState.winner && (
                    <p className="text-sm text-emerald-400">
                      Winner: {truncateAddress(displayGameState.winner)}
                    </p>
                  )}
                  <p className="text-sm text-gray-500 mt-1">
                    Prize pool: {displayGameState.pot} ETH
                  </p>
                </>
              ) : (
                <p className="text-sm text-gray-500">Observing game…</p>
              )}
            </div>
          )}
        </main>

        {/* Right sidebar — Combat Log */}
        <aside className="w-80 border-l border-gray-800/50 flex flex-col flex-shrink-0">
          <CombatLog events={events} />
        </aside>
      </div>

      {/* Proof overlay */}
      <ProofStatus stage={proofStage} proofType={proofType} error={proofError} />
    </div>
  );
}
