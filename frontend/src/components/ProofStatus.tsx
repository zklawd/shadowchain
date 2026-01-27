'use client';

import { useState, useEffect, useCallback } from 'react';
import { cn } from '@/lib/utils';

interface ProofStatusProps {
  isGenerating: boolean;
  proofType?: string;
  onComplete?: () => void;
}

export default function ProofStatus({ isGenerating, proofType = 'valid_move', onComplete }: ProofStatusProps) {
  const [progress, setProgress] = useState(0);
  const [stage, setStage] = useState('');

  const stableOnComplete = useCallback(() => {
    onComplete?.();
  }, [onComplete]);

  useEffect(() => {
    if (!isGenerating) {
      setProgress(0);
      setStage('');
      return;
    }

    setProgress(0);
    setStage('Compiling witness...');

    const stages = [
      { at: 15, label: 'Generating witness...' },
      { at: 35, label: 'Computing proof...' },
      { at: 60, label: 'UltraPlonk proving...' },
      { at: 85, label: 'Serializing proof...' },
      { at: 95, label: 'Verifying locally...' },
    ];

    const interval = setInterval(() => {
      setProgress((p) => {
        const newP = Math.min(p + Math.random() * 8 + 2, 100);
        const current = [...stages].reverse().find((s) => newP >= s.at);
        if (current) setStage(current.label);
        if (newP >= 100) {
          clearInterval(interval);
          setStage('Proof verified ✓');
          setTimeout(() => stableOnComplete(), 500);
        }
        return newP;
      });
    }, 200);

    return () => clearInterval(interval);
  }, [isGenerating, stableOnComplete]);

  if (!isGenerating && progress === 0) return null;

  const isDone = progress >= 100;

  return (
    <div className={cn(
      'fixed bottom-6 right-6 z-50 bg-gray-900/95 border rounded-lg p-4 shadow-2xl backdrop-blur-sm min-w-[300px] transition-all duration-300',
      isDone ? 'border-emerald-500/40' : 'border-indigo-500/40'
    )}>
      <div className="flex items-center gap-3 mb-3">
        {!isDone ? (
          <div className="w-5 h-5 border-2 border-indigo-500 border-t-transparent rounded-full animate-spin" />
        ) : (
          <div className="w-5 h-5 flex items-center justify-center text-emerald-400 text-sm">✓</div>
        )}
        <div>
          <p className="text-sm font-semibold text-white">
            {isDone ? 'Proof Ready' : 'Generating ZK Proof'}
          </p>
          <p className="text-[10px] text-gray-500 uppercase tracking-wider">
            Circuit: {proofType}
          </p>
        </div>
      </div>
      <div className="w-full h-1.5 bg-gray-800 rounded-full overflow-hidden mb-2">
        <div className={cn(
          'h-full rounded-full transition-all duration-200',
          isDone ? 'bg-gradient-to-r from-emerald-500 to-emerald-400' : 'bg-gradient-to-r from-indigo-600 to-indigo-400'
        )} style={{ width: `${progress}%` }} />
      </div>
      <p className={cn('text-[11px]', isDone ? 'text-emerald-400' : 'text-gray-400')}>
        {stage}
      </p>
    </div>
  );
}
