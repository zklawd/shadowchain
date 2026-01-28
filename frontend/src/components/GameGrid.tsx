'use client';

import { useCallback } from 'react';
import { Cell, Position } from '@/types/game';
import { cn } from '@/lib/utils';

interface GameGridProps {
  map: Cell[][];
  playerPosition: Position;
  visibleCells: Set<string>;
  enemyPositions?: Record<string, Position>;
  onCellClick?: (x: number, y: number) => void;
  isActive?: boolean;
}

export default function GameGrid({ map, playerPosition, visibleCells, enemyPositions = {}, onCellClick, isActive = true }: GameGridProps) {
  const isAdjacent = useCallback((x: number, y: number) => {
    const dx = Math.abs(x - playerPosition.x);
    const dy = Math.abs(y - playerPosition.y);
    return dx + dy === 1;
  }, [playerPosition]);

  const getEnemyAtCell = useCallback((x: number, y: number): boolean => {
    for (const pos of Object.values(enemyPositions)) {
      if (pos.x === x && pos.y === y && visibleCells.has(`${x},${y}`)) return true;
    }
    return false;
  }, [enemyPositions, visibleCells]);

  return (
    <div className="animate-grid-reveal">
      <div className="relative p-[1px] rounded-lg bg-gradient-to-br from-emerald-500/20 via-gray-800/50 to-indigo-500/20">
        <div className="bg-gray-950 rounded-lg p-2">
          {/* Top coord labels */}
          <div className="flex mb-0.5 ml-5">
            {Array.from({ length: 16 }, (_, i) => (
              <div key={i} className="w-[2.25rem] text-center text-[7px] text-gray-700 font-mono">
                {i.toString(16).toUpperCase()}
              </div>
            ))}
          </div>
          <div className="flex">
            {/* Left coord labels */}
            <div className="flex flex-col mr-0.5">
              {Array.from({ length: 16 }, (_, i) => (
                <div key={i} className="h-[2.25rem] flex items-center justify-center w-4 text-[7px] text-gray-700 font-mono">
                  {i.toString(16).toUpperCase()}
                </div>
              ))}
            </div>
            {/* Grid */}
            <div className="grid gap-[1px]" style={{ gridTemplateColumns: 'repeat(16, 2.25rem)', gridTemplateRows: 'repeat(16, 2.25rem)' }}>
              {map.map((row, y) =>
                row.map((cell, x) => {
                  const isPlayer = x === playerPosition.x && y === playerPosition.y;
                  const isVisible = visibleCells.has(`${x},${y}`);
                  const isEnemy = getEnemyAtCell(x, y);
                  const adjacent = isAdjacent(x, y);
                  const canMove = isActive && adjacent && cell.type !== 'wall' && isVisible;

                  let cellClass = 'cell-fog';
                  if (isPlayer) cellClass = 'cell-player';
                  else if (isEnemy) cellClass = 'cell-enemy';
                  else if (isVisible && cell.type === 'wall') cellClass = 'cell-wall';
                  else if (isVisible && cell.type === 'treasure') cellClass = 'cell-treasure';
                  else if (isVisible && cell.type === 'spawn') cellClass = 'cell-spawn';
                  else if (isVisible) cellClass = 'cell-visible';

                  return (
                    <button
                      key={`${x}-${y}`}
                      onClick={() => canMove && onCellClick?.(x, y)}
                      disabled={!canMove}
                      className={cn(
                        'w-full h-full rounded-[2px] relative flex items-center justify-center text-xs transition-all duration-150',
                        cellClass,
                        canMove && !isPlayer && 'cursor-pointer ring-1 ring-emerald-500/30 hover:ring-emerald-400/70 hover:scale-110 hover:z-10',
                        !canMove && 'cursor-default'
                      )}
                      title={isPlayer ? 'You' : isEnemy ? 'Enemy!' : isVisible ? `${cell.type} (${x},${y})` : 'Fog of War'}
                    >
                      {isPlayer && <span className="text-sm drop-shadow-[0_0_8px_rgba(16,185,129,0.9)]">◆</span>}
                      {isEnemy && !isPlayer && <span className="text-sm drop-shadow-[0_0_8px_rgba(239,68,68,0.9)]">◆</span>}
                      {isVisible && cell.type === 'treasure' && !isPlayer && !isEnemy && (
                        <span className="text-[10px] drop-shadow-[0_0_6px_rgba(245,158,11,0.8)]">✦</span>
                      )}
                      {isVisible && cell.type === 'wall' && <span className="text-[8px] text-gray-600">█</span>}
                      {isVisible && cell.type === 'spawn' && !isPlayer && !isEnemy && (
                        <span className="text-[9px] text-indigo-400/50">◎</span>
                      )}
                    </button>
                  );
                })
              )}
            </div>
          </div>
        </div>
      </div>
      {/* Legend */}
      <div className="flex items-center gap-4 mt-3 justify-center text-[9px] text-gray-500">
        <span className="flex items-center gap-1"><span className="w-3 h-3 rounded-sm cell-player inline-block" /> You</span>
        <span className="flex items-center gap-1"><span className="w-3 h-3 rounded-sm cell-enemy inline-block" /> Enemy</span>
        <span className="flex items-center gap-1"><span className="w-3 h-3 rounded-sm cell-wall inline-block" /> Wall</span>
        <span className="flex items-center gap-1"><span className="w-3 h-3 rounded-sm cell-treasure inline-block" /> Treasure</span>
        <span className="flex items-center gap-1"><span className="w-3 h-3 rounded-sm cell-spawn inline-block" /> Spawn</span>
        <span className="flex items-center gap-1"><span className="w-3 h-3 rounded-sm cell-fog inline-block border border-gray-800" /> Fog</span>
      </div>
    </div>
  );
}
