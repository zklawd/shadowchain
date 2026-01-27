'use client';

import { Player } from '@/types/game';
import { truncateAddress, cn } from '@/lib/utils';

interface PlayerCardProps {
  player: Player;
  isCurrentPlayer: boolean;
}

export default function PlayerCard({ player, isCurrentPlayer }: PlayerCardProps) {
  const hpPct = (player.hp / player.maxHp) * 100;
  const hpColor = hpPct > 60 ? 'bg-emerald-500' : hpPct > 30 ? 'bg-amber-500' : 'bg-red-500';

  return (
    <div className={cn(
      'border rounded-lg p-3 transition-all duration-300',
      isCurrentPlayer
        ? 'bg-emerald-500/5 border-emerald-500/30 shadow-[0_0_15px_rgba(16,185,129,0.08)]'
        : player.isAlive
          ? 'bg-gray-900/60 border-gray-800 hover:border-gray-700'
          : 'bg-gray-900/30 border-gray-800/40 opacity-50'
    )}>
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <div className={cn(
            'w-2 h-2 rounded-full',
            !player.isAlive ? 'bg-gray-600' :
            isCurrentPlayer ? 'bg-emerald-400 animate-pulse' : 'bg-amber-400'
          )} />
          <span className={cn(
            'text-sm font-semibold',
            isCurrentPlayer ? 'text-emerald-400' : 'text-gray-300'
          )}>
            {truncateAddress(player.address)}
          </span>
          {isCurrentPlayer && (
            <span className="text-[9px] px-1.5 py-0.5 bg-emerald-500/20 text-emerald-400 rounded border border-emerald-500/30 uppercase tracking-wider font-bold">
              You
            </span>
          )}
        </div>
        {!player.isAlive && (
          <span className="text-[9px] px-1.5 py-0.5 bg-red-500/15 text-red-400 rounded border border-red-500/30 uppercase tracking-wider font-bold">
            Dead
          </span>
        )}
      </div>

      <div className="mb-2">
        <div className="flex justify-between text-[10px] text-gray-500 mb-1">
          <span>HP</span>
          <span className="tabular-nums">{player.hp}/{player.maxHp}</span>
        </div>
        <div className="w-full h-1.5 bg-gray-800 rounded-full overflow-hidden">
          <div className={cn('h-full rounded-full transition-all duration-500', hpColor)}
               style={{ width: `${hpPct}%` }} />
        </div>
      </div>

      <div className="flex gap-3 text-[10px]">
        <span className="text-red-400">⚔ {player.attack}</span>
        <span className="text-blue-400">🛡 {player.defense}</span>
        <span className="text-amber-400">★ {player.score}</span>
      </div>

      {player.artifacts.length > 0 && (
        <div className="mt-2 flex flex-wrap gap-1">
          {player.artifacts.map((a) => (
            <span key={a.id} className="text-[9px] px-1.5 py-0.5 bg-amber-500/10 text-amber-400/80 rounded border border-amber-500/20" title={a.effect}>
              {a.name}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}
