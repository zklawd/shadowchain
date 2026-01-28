'use client';

import { useState, useMemo, useEffect } from 'react';
import Link from 'next/link';
import { useReadContract, useReadContracts, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther, formatEther } from 'viem';
import { shadowChainGameConfig, gameStateToStatus } from '@/lib/contracts';
import { truncateAddress, formatEth, cn } from '@/lib/utils';
import WalletConnect from '@/components/WalletConnect';
import type { LobbyGame } from '@/types/game';

/* ── Status badge ─────────────────────────────────────── */

function StatusBadge({ status }: { status: LobbyGame['status'] }) {
  const map = {
    waiting: { css: 'bg-amber-500/10 text-amber-400 border-amber-500/30', label: 'WAITING' },
    active:  { css: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30', label: 'LIVE' },
    ended:   { css: 'bg-gray-500/10 text-gray-500 border-gray-700', label: 'ENDED' },
  } as const;
  const s = map[status];
  return (
    <span className={cn('text-[10px] px-2 py-0.5 rounded border font-bold tracking-wider inline-flex items-center gap-1.5', s.css)}>
      {status === 'active' && <span className="w-1.5 h-1.5 bg-emerald-400 rounded-full animate-pulse" />}
      {s.label}
    </span>
  );
}

/* ── Create Game modal ────────────────────────────────── */

function CreateGameModal({ onClose, onCreated }: { onClose: () => void; onCreated?: () => void }) {
  const [fee, setFee] = useState('0.01');
  const [maxP, setMaxP] = useState('2');
  const pot = (parseFloat(fee || '0') * parseInt(maxP || '0')).toFixed(4);

  const { writeContract, data: txHash, isPending: isWriting, error: writeError } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({ hash: txHash });

  // Auto-close modal after tx confirms + refetch game list
  useEffect(() => {
    if (isConfirmed) {
      onCreated?.();
      const t = setTimeout(() => onClose(), 1200);
      return () => clearTimeout(t);
    }
  }, [isConfirmed, onClose, onCreated]);

  const handleCreate = () => {
    const seed = BigInt(Math.floor(Math.random() * 2 ** 64));
    const maxPlayers = parseInt(maxP);
    const entryFeeWei = parseEther(fee || '0');

    writeContract({
      ...shadowChainGameConfig,
      functionName: 'createGame',
      args: [seed, maxPlayers, entryFeeWei],
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/80 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-gray-900 border border-gray-700 rounded-xl p-8 max-w-md w-full mx-4 shadow-2xl">
        <button onClick={onClose} className="absolute top-4 right-4 text-gray-500 hover:text-gray-300 transition-colors text-lg">✕</button>

        <h2 className="text-xl font-bold text-white mb-1">Create Arena</h2>
        <p className="text-sm text-gray-500 mb-6">Deploy a new shadow arena on Sepolia</p>

        <div className="space-y-5">
          <div>
            <label className="text-[10px] text-gray-400 uppercase tracking-[0.2em] block mb-2">Entry Fee (ETH)</label>
            <input
              type="text"
              value={fee}
              onChange={(e) => setFee(e.target.value)}
              className="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white text-sm focus:border-emerald-500/50 focus:outline-none focus:ring-1 focus:ring-emerald-500/20 transition-all"
              placeholder="0.01"
            />
          </div>

          <div>
            <label className="text-[10px] text-gray-400 uppercase tracking-[0.2em] block mb-2">Max Players</label>
            <div className="grid grid-cols-4 gap-2">
              {['2', '4', '6', '8'].map((n) => (
                <button
                  key={n}
                  onClick={() => setMaxP(n)}
                  className={cn(
                    'py-2.5 rounded-lg border text-sm font-semibold transition-all',
                    maxP === n
                      ? 'bg-emerald-500/10 border-emerald-500/40 text-emerald-400'
                      : 'bg-gray-800 border-gray-700 text-gray-400 hover:border-gray-600'
                  )}
                >
                  {n}
                </button>
              ))}
            </div>
          </div>

          <div className="bg-gray-800/50 border border-gray-700/50 rounded-lg p-4 text-xs space-y-1.5">
            <div className="flex justify-between"><span className="text-gray-500">Map Size</span><span className="text-gray-300">16 × 16</span></div>
            <div className="flex justify-between"><span className="text-gray-500">Turns</span><span className="text-gray-300">50</span></div>
            <div className="flex justify-between"><span className="text-gray-500">Turn Timer</span><span className="text-gray-300">60 s</span></div>
            <div className="flex justify-between"><span className="text-gray-500">Max Pot</span><span className="text-emerald-400 font-semibold">{pot} ETH</span></div>
          </div>

          {writeError && (
            <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-3 text-xs text-red-400">
              {writeError.message.includes('User rejected')
                ? 'Transaction rejected'
                : `Error: ${writeError.message.slice(0, 100)}`}
            </div>
          )}

          {isConfirmed && (
            <div className="bg-emerald-500/10 border border-emerald-500/30 rounded-lg p-3 text-xs text-emerald-400">
              ✓ Arena created! Transaction confirmed.
            </div>
          )}

          <button
            onClick={handleCreate}
            disabled={isWriting || isConfirming}
            className={cn(
              'w-full py-3.5 bg-emerald-500/10 border-2 border-emerald-500/50 text-emerald-400 font-semibold rounded-lg transition-all duration-300 hover:bg-emerald-500/20 hover:border-emerald-400 hover:shadow-[0_0_30px_rgba(16,185,129,0.12)] active:scale-[0.98]',
              (isWriting || isConfirming) && 'opacity-50 cursor-not-allowed'
            )}
          >
            {isWriting ? 'Confirm in wallet…' : isConfirming ? 'Deploying…' : 'Deploy Arena'}
          </button>
        </div>
      </div>
    </div>
  );
}

/* ── Hook: read all games from chain ──────────────────── */

interface OnChainGame {
  id: string;
  creator: string;
  entryFee: string;
  maxPlayers: number;
  currentPlayers: number;
  status: 'waiting' | 'active' | 'ended';
  prizePool: string;
}

function useOnChainGames(): { games: OnChainGame[]; isLoading: boolean; error: Error | null; refetch: () => void } {
  // Read nextGameId to know how many games exist
  const { data: nextGameId, isLoading: loadingId, error: idError, refetch: refetchId } = useReadContract({
    ...shadowChainGameConfig,
    functionName: 'nextGameId',
  });

  const gameCount = nextGameId ? Number(nextGameId) : 0;

  // Build contracts array for batch read
  const gameContracts = useMemo(() => {
    if (gameCount <= 1) return [];
    return Array.from({ length: gameCount - 1 }, (_, i) => ({
      ...shadowChainGameConfig,
      functionName: 'getGame' as const,
      args: [BigInt(i + 1)] as const,
    }));
  }, [gameCount]);

  const { data: gamesData, isLoading: loadingGames, error: gamesError, refetch: refetchGames } = useReadContracts({
    contracts: gameContracts,
    query: { enabled: gameCount > 0 },
  });

  const refetch = () => {
    refetchId().then(() => refetchGames());
  };

  const games = useMemo(() => {
    if (!gamesData) return [];
    return gamesData
      .map((result, _idx) => {
        if (result.status !== 'success' || !result.result) return null;
        const g = result.result as {
          id: bigint;
          seed: bigint;
          entryFee: bigint;
          prizePool: bigint;
          wallBitmap: bigint;
          treasureBitmap: bigint;
          currentTurn: number;
          maxTurns: number;
          maxPlayers: number;
          playerCount: number;
          aliveCount: number;
          turnDeadline: bigint;
          creator: string;
          winner: string;
          state: number;
        };
        return {
          id: g.id.toString(),
          creator: g.creator,
          entryFee: formatEther(g.entryFee),
          maxPlayers: g.maxPlayers,
          currentPlayers: g.playerCount,
          status: gameStateToStatus(g.state),
          prizePool: formatEther(g.prizePool),
        } satisfies OnChainGame;
      })
      .filter((g): g is OnChainGame => g !== null)
      .filter((g) => g.id !== '0') // Filter out phantom Game #0 from contract init
      .reverse(); // newest first
  }, [gamesData]);

  return {
    games,
    isLoading: loadingId || loadingGames,
    error: (idError || gamesError) as Error | null,
    refetch,
  };
}

/* ── Main page ────────────────────────────────────────── */

export default function LobbyPage() {
  const [showCreate, setShowCreate] = useState(false);
  const [filter, setFilter] = useState<'all' | 'waiting' | 'active' | 'ended'>('all');

  const { games: onChainGames, isLoading, error, refetch } = useOnChainGames();

  const allGames = onChainGames;
  const filteredGames = filter === 'all' ? allGames : allGames.filter((g) => g.status === filter);

  const counts = useMemo(() => ({
    all: allGames.length,
    waiting: allGames.filter((g) => g.status === 'waiting').length,
    active: allGames.filter((g) => g.status === 'active').length,
    ended: allGames.filter((g) => g.status === 'ended').length,
  }), [allGames]);

  return (
    <div className="min-h-screen bg-gray-950">
      {/* Header */}
      <header className="border-b border-gray-800/50 px-8 py-4">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2 hover:opacity-80 transition-opacity">
            <span className="text-emerald-400 text-lg">◆</span>
            <span className="text-xs font-bold text-gray-400 tracking-[0.25em]">SHADOWCHAIN</span>
          </Link>
          <div className="flex items-center gap-5">
            <span className="text-xs text-emerald-400 border-b border-emerald-500/30 pb-0.5">Lobby</span>
            <span className="text-[9px] px-2 py-0.5 bg-purple-500/10 text-purple-400 border border-purple-500/30 rounded tracking-wider font-bold">SEPOLIA</span>
            <WalletConnect />
          </div>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-8 py-12">
        {/* Title row */}
        <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4 mb-10">
          <div>
            <h1 className="text-2xl sm:text-3xl font-bold text-white mb-2">Shadow Arena Lobby</h1>
            <p className="text-sm text-gray-500">Choose your battleground or create a new arena</p>
          </div>
          <button
            onClick={() => setShowCreate(true)}
            className="self-start sm:self-auto px-6 py-3 bg-emerald-500/10 border border-emerald-500/40 text-emerald-400 text-sm font-semibold rounded-lg transition-all duration-300 hover:bg-emerald-500/20 hover:border-emerald-400 hover:shadow-[0_0_20px_rgba(16,185,129,0.12)] active:scale-95 flex items-center gap-2"
          >
            <span className="text-base leading-none">+</span> Create Arena
          </button>
        </div>

        {/* Tabs */}
        <div className="flex items-center gap-1 mb-8 bg-gray-900/50 rounded-lg p-1 border border-gray-800/50 w-fit">
          {(['all', 'waiting', 'active', 'ended'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={cn(
                'px-4 py-2 rounded-md text-xs font-semibold uppercase tracking-wider transition-all',
                filter === f ? 'bg-gray-800 text-white shadow' : 'text-gray-500 hover:text-gray-300'
              )}
            >
              {f} <span className="text-gray-600 ml-1">{counts[f]}</span>
            </button>
          ))}
        </div>

        {/* Loading state */}
        {isLoading && (
          <div className="text-center py-20">
            <div className="text-4xl mb-4 animate-pulse opacity-40">◆</div>
            <p className="text-gray-500 text-sm">Reading on-chain data…</p>
          </div>
        )}

        {/* Error state */}
        {error && !isLoading && (
          <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-6 text-center">
            <p className="text-red-400 text-sm mb-1">Failed to load games from Sepolia</p>
            <p className="text-red-400/60 text-xs">{error.message?.slice(0, 120)}</p>
          </div>
        )}

        {/* Game list */}
        {!isLoading && (
          <div className="space-y-3">
            {filteredGames.map((g) => (
              <div
                key={g.id}
                className={cn(
                  'bg-gray-900/50 border rounded-xl p-5 transition-all duration-300 group',
                  g.status === 'active'  ? 'border-emerald-500/15 hover:border-emerald-500/35' :
                  g.status === 'waiting' ? 'border-amber-500/10 hover:border-amber-500/25' :
                                           'border-gray-800/40 hover:border-gray-700'
                )}
              >
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                  {/* Left */}
                  <div className="flex items-center gap-5">
                    <div className="w-14 text-center flex-shrink-0">
                      <div className="text-xl font-bold text-white">#{g.id}</div>
                      <div className="text-[9px] text-gray-600 uppercase tracking-wider">Arena</div>
                    </div>
                    <div className="w-px h-9 bg-gray-800 hidden sm:block" />
                    <div className="space-y-1.5">
                      <div className="flex flex-wrap items-center gap-2">
                        <StatusBadge status={g.status} />
                        <span className="text-xs text-gray-500">by {truncateAddress(g.creator)}</span>
                      </div>
                      <div className="flex items-center gap-4 text-xs text-gray-400">
                        <span><span className="text-gray-600">Fee: </span><span className="text-amber-400 font-semibold">{formatEth(g.entryFee)}</span></span>
                        <span><span className="text-gray-600">Pot: </span><span className="text-emerald-400 font-semibold">{formatEth(g.prizePool)}</span></span>
                        <span className="text-gray-600">16×16</span>
                      </div>
                    </div>
                  </div>

                  {/* Right */}
                  <div className="flex items-center gap-5">
                    {/* Player dots */}
                    <div className="text-right">
                      <div className="flex items-center gap-1 justify-end mb-1">
                        {Array.from({ length: g.maxPlayers }, (_, i) => (
                          <div
                            key={i}
                            className={cn(
                              'w-2 h-2 rounded-full border transition-all',
                              i < g.currentPlayers
                                ? g.status === 'active' ? 'bg-emerald-400 border-emerald-400' : 'bg-amber-400 border-amber-400'
                                : 'border-gray-700'
                            )}
                          />
                        ))}
                      </div>
                      <div className="text-[10px] text-gray-500">{g.currentPlayers}/{g.maxPlayers} players</div>
                    </div>

                    {/* Action */}
                    {g.status === 'waiting' && (
                      <Link href={`/game/${g.id}`} className="px-5 py-2.5 bg-amber-500/10 border border-amber-500/30 text-amber-400 text-xs font-semibold rounded-lg transition-all hover:bg-amber-500/20 hover:border-amber-400 active:scale-95">
                        Join Game
                      </Link>
                    )}
                    {g.status === 'active' && (
                      <Link href={`/game/${g.id}`} className="px-5 py-2.5 bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-semibold rounded-lg transition-all hover:bg-emerald-500/20 hover:border-emerald-400 active:scale-95">
                        Watch
                      </Link>
                    )}
                    {g.status === 'ended' && (
                      <span className="px-5 py-2.5 text-xs text-gray-600 font-semibold">Finished</span>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {!isLoading && filteredGames.length === 0 && !error && (
          <div className="text-center py-20">
            <div className="text-4xl mb-4 opacity-20">◆</div>
            <p className="text-gray-500 text-sm">
              {allGames.length === 0 ? 'No arenas yet — be the first to create one' : 'No arenas match this filter'}
            </p>
          </div>
        )}
      </main>

      {showCreate && <CreateGameModal onClose={() => setShowCreate(false)} onCreated={refetch} />}
    </div>
  );
}
