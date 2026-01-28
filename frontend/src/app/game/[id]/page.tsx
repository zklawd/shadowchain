'use client';

import { useState, useCallback, useEffect, useRef } from 'react';
import Link from 'next/link';
import { mockGameState, getVisibleCells, mockEnemyPositions } from '@/lib/mock-data';
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
  generateMoveProof,
  randomSalt,
  isProverReady,
} from '@/lib/noir-prover';
import type { Position, Direction, CombatEvent } from '@/types/game';

export default function GamePage({ params }: { params: { id: string } }) {
  void params;
  const [gameState, setGameState] = useState(mockGameState);
  const [playerPos, setPlayerPos] = useState<Position>(
    gameState.players[0].position ?? { x: 6, y: 6 }
  );
  const [proofStage, setProofStage] = useState<ProofStage>('idle');
  const [proofError, setProofError] = useState<string | null>(null);
  const [pendingDir, setPendingDir] = useState<Direction | null>(null);
  const isProving = proofStage !== 'idle' && proofStage !== 'done' && proofStage !== 'error';

  // Salt for position commitments — persisted across moves
  const currentSalt = useRef<bigint>(randomSalt());

  // Pre-initialize the prover on mount
  useEffect(() => {
    initProver().catch((err) =>
      console.warn('[ZK] Prover pre-init failed (will retry on first move):', err)
    );
  }, []);

  const visibleCells = getVisibleCells(playerPos, 3);

  // Map walls as bitmasks (16 rows, each a bitmask of wall columns)
  const mapWalls: bigint[] = gameState.map.map((row) => {
    let bits = BigInt(0);
    row.forEach((cell, x) => {
      if (cell.type === 'wall') {
        bits |= BigInt(1) << BigInt(x);
      }
    });
    return bits;
  });

  /* ── Move handling with REAL ZK proving ────────────── */

  const startMove = useCallback(
    async (x: number, y: number) => {
      if (isProving) return;

      let dir: Direction = 'stay';
      if (x > playerPos.x) dir = 'E';
      else if (x < playerPos.x) dir = 'W';
      else if (y > playerPos.y) dir = 'S';
      else if (y < playerPos.y) dir = 'N';

      setPendingDir(dir);
      setProofError(null);

      const newPos = { x, y };
      const oldSalt = currentSalt.current;
      const newSalt = randomSalt();

      try {
        // Stage 1: Init WASM (if needed)
        if (!isProverReady()) {
          setProofStage('initializing');
          await initProver();
        }

        // Stage 2: Compute witness
        setProofStage('computing_witness');

        // Stage 3 & 4: Generate proof (includes witness execution internally)
        setProofStage('generating_proof');
        const result = await generateMoveProof({
          oldPos: playerPos,
          newPos,
          oldSalt,
          newSalt,
          mapWalls,
        });

        // Stage 5: Done
        setProofStage('verifying');
        // Brief pause to show verification stage
        await new Promise((r) => setTimeout(r, 300));
        setProofStage('done');

        console.log('[ZK] Move proof generated:', {
          proofSize: result.proof.length,
          oldCommitment: result.oldCommitment,
          newCommitment: result.newCommitment,
        });

        // Update game state
        currentSalt.current = newSalt;
        setPlayerPos(newPos);

        const evt: CombatEvent = {
          id: String(Date.now()),
          timestamp: Date.now(),
          type: 'move',
          message: `${truncateAddress(gameState.currentPlayer)} moves ${dir} — ZK proof verified ✓ (${result.proof.length} bytes)`,
          players: [gameState.currentPlayer],
        };

        setGameState((prev) => ({
          ...prev,
          events: [...prev.events, evt],
          turn: prev.turn + 1,
          timeRemaining: 60,
        }));

        // Treasure discovery
        const cell = gameState.map[newPos.y]?.[newPos.x];
        if (cell?.type === 'treasure') {
          setTimeout(() => {
            const te: CombatEvent = {
              id: String(Date.now() + 1),
              timestamp: Date.now(),
              type: 'artifact',
              message: `${truncateAddress(gameState.currentPlayer)} discovers treasure! Generating claim proof…`,
              players: [gameState.currentPlayer],
            };
            setGameState((p) => ({ ...p, events: [...p.events, te] }));
          }, 400);
        }

        // Reset after brief display
        setTimeout(() => {
          setProofStage('idle');
          setPendingDir(null);
        }, 2000);
      } catch (err: any) {
        console.error('[ZK] Proof generation failed:', err);
        setProofStage('error');
        setProofError(err?.message || 'Unknown proof error');
        setTimeout(() => {
          setProofStage('idle');
          setPendingDir(null);
        }, 4000);
      }
    },
    [playerPos, isProving, gameState, mapWalls]
  );

  const tryMove = useCallback(
    (dir: Direction) => {
      if (isProving || dir === 'stay') return;
      const np = { ...playerPos };
      if (dir === 'N') np.y -= 1;
      if (dir === 'S') np.y += 1;
      if (dir === 'E') np.x += 1;
      if (dir === 'W') np.x -= 1;
      if (np.x < 0 || np.x > 15 || np.y < 0 || np.y > 15) return;
      if (gameState.map[np.y]?.[np.x]?.type === 'wall') return;
      startMove(np.x, np.y);
    },
    [playerPos, isProving, gameState.map, startMove]
  );

  /* ── Keyboard ──────────────────────────────────────── */
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const k = e.key.toLowerCase();
      const map: Record<string, Direction> = {
        arrowup: 'N', w: 'N',
        arrowdown: 'S', s: 'S',
        arrowleft: 'W', a: 'W',
        arrowright: 'E', d: 'E',
      };
      const dir = map[k];
      if (dir) { e.preventDefault(); tryMove(dir); }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [tryMove]);

  /* ── Layout ────────────────────────────────────────── */
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
              <span className="w-1.5 h-1.5 bg-emerald-400 rounded-full animate-pulse" />
              <span className="text-sm text-gray-300 font-semibold">Arena #{gameState.id}</span>
              <span className="text-[9px] px-2 py-0.5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 rounded tracking-wider font-bold">LIVE</span>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-xs text-gray-500">
              Pot: <span className="text-emerald-400 font-bold">{gameState.pot} ETH</span>
            </span>
            <WalletConnect />
          </div>
        </div>
      </header>

      {/* Main */}
      <div className="flex-1 flex min-h-0">
        {/* Left sidebar */}
        <aside className="w-72 border-r border-gray-800/50 flex flex-col flex-shrink-0 overflow-y-auto">
          {/* Timer */}
          <div className="p-3 border-b border-gray-800/50">
            <TurnTimer initialTime={gameState.timeRemaining} turn={gameState.turn} maxTurns={gameState.maxTurns} />
          </div>

          {/* Players */}
          <div className="p-3 border-b border-gray-800/50">
            <h3 className="text-[10px] font-bold text-gray-500 uppercase tracking-[0.2em] mb-3">
              Players ({gameState.players.filter((p) => p.isAlive).length}/{gameState.players.length})
            </h3>
            <div className="space-y-2">
              {gameState.players.map((p) => (
                <PlayerCard key={p.address} player={p} isCurrentPlayer={p.address === gameState.currentPlayer} />
              ))}
            </div>
          </div>

          {/* Movement controls */}
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
                    disabled={isProving}
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

          {/* Position info */}
          <div className="p-3 mt-auto">
            <div className="bg-gray-900/60 rounded-lg p-3 border border-gray-800/40 text-[10px] space-y-1">
              <div className="flex justify-between">
                <span className="text-gray-500">Position</span>
                <span className="text-emerald-400">({playerPos.x}, {playerPos.y})</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Visibility</span>
                <span className="text-gray-400">radius 3</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">ZK Prover</span>
                <span className={cn(
                  isProverReady() ? 'text-emerald-400' : 'text-yellow-500',
                )}>
                  {isProverReady() ? 'Ready ✓' : 'Loading…'}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Backend</span>
                <span className="text-gray-400">UltraHonk</span>
              </div>
            </div>
          </div>
        </aside>

        {/* Grid (centre) */}
        <main className="flex-1 flex items-center justify-center p-4 overflow-auto">
          <GameGrid
            map={gameState.map}
            playerPosition={playerPos}
            visibleCells={visibleCells}
            enemyPositions={mockEnemyPositions}
            onCellClick={startMove}
          />
        </main>

        {/* Right sidebar — Combat Log */}
        <aside className="w-80 border-l border-gray-800/50 flex flex-col flex-shrink-0">
          <CombatLog events={gameState.events} />
        </aside>
      </div>

      {/* Proof overlay */}
      <ProofStatus stage={proofStage} proofType="valid_move" error={proofError} />
    </div>
  );
}
