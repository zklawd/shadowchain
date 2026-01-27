'use client';

import { useState, useEffect } from 'react';
import { formatTimer, cn } from '@/lib/utils';

interface TurnTimerProps {
  initialTime: number;
  turn: number;
  maxTurns: number;
}

export default function TurnTimer({ initialTime, turn, maxTurns }: TurnTimerProps) {
  const [time, setTime] = useState(initialTime);

  useEffect(() => {
    setTime(initialTime);
  }, [initialTime]);

  useEffect(() => {
    if (time <= 0) return;
    const interval = setInterval(() => {
      setTime((t) => Math.max(0, t - 1));
    }, 1000);
    return () => clearInterval(interval);
  }, [time]);

  const isLow = time <= 10;
  const isCritical = time <= 5;
  const percentage = (time / 60) * 100;

  return (
    <div className="bg-gray-900/80 border border-gray-800 rounded-lg p-4 backdrop-blur-sm">
      <div className="flex items-center justify-between mb-2">
        <span className="text-xs text-gray-500 uppercase tracking-widest">Turn</span>
        <span className="text-xs text-gray-500 uppercase tracking-widest">Timer</span>
      </div>
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-baseline gap-1">
          <span className="text-2xl font-bold text-white">{turn}</span>
          <span className="text-sm text-gray-500">/ {maxTurns}</span>
        </div>
        <span
          className={cn(
            'text-3xl font-bold tabular-nums',
            isCritical && 'text-red-400 animate-pulse',
            isLow && !isCritical && 'text-amber-400',
            !isLow && 'text-emerald-400'
          )}
        >
          {formatTimer(time)}
        </span>
      </div>
      {/* Turn progress */}
      <div className="w-full h-1 bg-gray-800 rounded-full mb-2">
        <div
          className="h-full bg-gradient-to-r from-emerald-500 to-emerald-400 rounded-full transition-all duration-300"
          style={{ width: `${(turn / maxTurns) * 100}%` }}
        />
      </div>
      {/* Timer bar */}
      <div className="w-full h-2 bg-gray-800 rounded-full overflow-hidden">
        <div
          className={cn(
            'h-full rounded-full transition-all duration-1000',
            isCritical && 'bg-gradient-to-r from-red-600 to-red-400',
            isLow && !isCritical && 'bg-gradient-to-r from-amber-600 to-amber-400',
            !isLow && 'bg-gradient-to-r from-emerald-600 to-emerald-400'
          )}
          style={{ width: `${percentage}%` }}
        />
      </div>
    </div>
  );
}
