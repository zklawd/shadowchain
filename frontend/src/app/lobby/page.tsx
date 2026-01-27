'use client';

import { useState } from 'react';
import Link from 'next/link';
import { mockLobbyGames } from '@/lib/mock-data';
import { truncateAddress, formatEth, timeAgo, cn } from '@/lib/utils';
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

function CreateGameModal({ onClose }: { onClose: () => void }) {
  const [fee, setFee] = useState('0.1');
  const [maxP, setMaxP] = useState('4');
  const pot = (parseFloat(fee || '0') * parseInt(maxP || '0')).toFixed(2);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/80 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-gray-900 border border-gray-700 rounded-xl p-8 max-w-md w-full mx-4 shadow-2xl">
        <button onClick={onClose} className="absolute top-4 right-4 text-gray-500 hover:text-gray-300 transition-colors text-lg">✕</button>

        <h2 className="text-xl font-bold text-white mb-1">Create Arena</h2>
        <p className="text-sm text-gray-500 mb-6">Deploy a new shadow arena contract</p>

        <div className="space-y-5">
          <div>
            <label className="text-[10px] text-gray-400 uppercase tracking-[0.2em] block mb-2">Entry Fee (ETH)</label>
            <input
              type="text"
              value={fee}
              onChange={(e) => setFee(e.target.value)}
              className="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white text-sm focus:border-emerald-500/50 focus:outline-none focus:ring-1 focus:ring-emerald-500/20 transition-all"
              placeholder="0.1"
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

          <button className="w-full py-3.5 bg-emerald-500/10 border-2 border-emerald-500/50 text-emerald-400 font-semibold rounded-lg transition-all duration-300 hover:bg-emerald-500/20 hover:border-emerald-400 hover:shadow-[0_0_30px_rgba(16,185,129,0.12)] active:scale-[0.98]">
            Deploy Arena
          </button>
        </div>
      </div>
    </div>
  );
}

/* ── Main page ────────────────────────────────────────── */

export default function LobbyPage() {
  const [showCreate, setShowCreate] = useState(false);
  const [filter, setFilter] = useState<'all' | 'waiting' | 'active' | 'ended'>('all');

  const games = filter === 'all' ? mockLobbyGames : mockLobbyGames.filter((g) => g.status === filter);

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
          {(['all', 'waiting', 'active', 'ended'] as const).map((f) => {
            const count = f === 'all' ? mockLobbyGames.length : mockLobbyGames.filter((g) => g.status === f).length;
            return (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={cn(
                  'px-4 py-2 rounded-md text-xs font-semibold uppercase tracking-wider transition-all',
                  filter === f ? 'bg-gray-800 text-white shadow' : 'text-gray-500 hover:text-gray-300'
                )}
              >
                {f} <span className="text-gray-600 ml-1">{count}</span>
              </button>
            );
          })}
        </div>

        {/* Game list */}
        <div className="space-y-3">
          {games.map((g) => (
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
                      <span className="text-[10px] text-gray-600">{timeAgo(g.createdAt)}</span>
                    </div>
                    <div className="flex items-center gap-4 text-xs text-gray-400">
                      <span><span className="text-gray-600">Fee: </span><span className="text-amber-400 font-semibold">{formatEth(g.entryFee)}</span></span>
                      <span><span className="text-gray-600">Pot: </span><span className="text-emerald-400 font-semibold">{formatEth((parseFloat(g.entryFee) * g.currentPlayers).toFixed(2))}</span></span>
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

        {games.length === 0 && (
          <div className="text-center py-20">
            <div className="text-4xl mb-4 opacity-20">◆</div>
            <p className="text-gray-500 text-sm">No arenas found</p>
          </div>
        )}
      </main>

      {showCreate && <CreateGameModal onClose={() => setShowCreate(false)} />}
    </div>
  );
}
