'use client';

import { useRef, useEffect } from 'react';
import { CombatEvent } from '@/types/game';
import { timeAgo, cn } from '@/lib/utils';

interface CombatLogProps {
  events: CombatEvent[];
}

const eventConfig: Record<CombatEvent['type'], { icon: string; color: string; border: string }> = {
  move:     { icon: '→', color: 'text-gray-400',   border: 'border-gray-800' },
  combat:   { icon: '⚔', color: 'text-red-400',    border: 'border-red-500/20' },
  artifact: { icon: '✦', color: 'text-amber-400',  border: 'border-amber-500/20' },
  system:   { icon: '◆', color: 'text-indigo-400', border: 'border-indigo-500/20' },
  death:    { icon: '☠', color: 'text-red-500',    border: 'border-red-500/30' },
  explore:  { icon: '◎', color: 'text-emerald-400', border: 'border-emerald-500/20' },
};

export default function CombatLog({ events }: CombatLogProps) {
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [events]);

  return (
    <div className="bg-gray-900/80 border border-gray-800 rounded-lg backdrop-blur-sm flex flex-col h-full">
      <div className="px-4 py-3 border-b border-gray-800 flex-shrink-0">
        <h3 className="text-[10px] font-bold text-gray-400 uppercase tracking-[0.2em] flex items-center gap-2">
          <span className="w-1.5 h-1.5 bg-red-500 rounded-full animate-pulse" />
          Combat Log
        </h3>
      </div>
      <div ref={scrollRef} className="flex-1 overflow-y-auto p-3 space-y-1.5 min-h-0">
        {events.map((event, i) => {
          const cfg = eventConfig[event.type];
          return (
            <div key={event.id} className={cn(
              'flex items-start gap-2 p-2 rounded border text-xs bg-gray-900/40',
              cfg.border,
              i === events.length - 1 && 'animate-fade-in'
            )}>
              <span className={cn('flex-shrink-0 mt-0.5', cfg.color)}>{cfg.icon}</span>
              <div className="flex-1 min-w-0">
                <p className={cn('break-words leading-relaxed', cfg.color)}>{event.message}</p>
                <span className="text-[10px] text-gray-600 mt-0.5 block">{timeAgo(event.timestamp)}</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
