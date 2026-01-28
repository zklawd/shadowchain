'use client';

import { useEffect, useState } from 'react';
import { cn } from '@/lib/utils';

export type ProofStage =
  | 'idle'
  | 'initializing'
  | 'computing_witness'
  | 'generating_proof'
  | 'verifying'
  | 'done'
  | 'error';

interface ProofStatusProps {
  stage: ProofStage;
  proofType?: string;
  error?: string | null;
}

const STAGE_LABELS: Record<ProofStage, string> = {
  idle: '',
  initializing: 'Initializing WASM prover…',
  computing_witness: 'Computing witness…',
  generating_proof: 'Generating UltraHonk proof…',
  verifying: 'Verifying proof locally…',
  done: 'Proof verified ✓',
  error: 'Proof generation failed ✗',
};

const STAGE_PROGRESS: Record<ProofStage, number> = {
  idle: 0,
  initializing: 10,
  computing_witness: 30,
  generating_proof: 60,
  verifying: 90,
  done: 100,
  error: 100,
};

export default function ProofStatus({ stage, proofType = 'valid_move', error }: ProofStatusProps) {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (stage !== 'idle') {
      setVisible(true);
    } else {
      // Small delay before hiding to show the "done" state
      const t = setTimeout(() => setVisible(false), 300);
      return () => clearTimeout(t);
    }
  }, [stage]);

  // Auto-hide after done
  useEffect(() => {
    if (stage === 'done') {
      const t = setTimeout(() => setVisible(false), 2000);
      return () => clearTimeout(t);
    }
  }, [stage]);

  if (!visible) return null;

  const isDone = stage === 'done';
  const isError = stage === 'error';
  const isActive = !isDone && !isError && stage !== 'idle';
  const progress = STAGE_PROGRESS[stage];

  return (
    <div
      className={cn(
        'fixed bottom-6 right-6 z-50 bg-gray-900/95 border rounded-lg p-4 shadow-2xl backdrop-blur-sm min-w-[300px] transition-all duration-300',
        isDone && 'border-emerald-500/40',
        isError && 'border-red-500/40',
        isActive && 'border-indigo-500/40',
      )}
    >
      <div className="flex items-center gap-3 mb-3">
        {isActive && (
          <div className="w-5 h-5 border-2 border-indigo-500 border-t-transparent rounded-full animate-spin" />
        )}
        {isDone && (
          <div className="w-5 h-5 flex items-center justify-center text-emerald-400 text-sm">✓</div>
        )}
        {isError && (
          <div className="w-5 h-5 flex items-center justify-center text-red-400 text-sm">✗</div>
        )}
        <div>
          <p className="text-sm font-semibold text-white">
            {isDone ? 'Proof Ready' : isError ? 'Proof Error' : 'Generating ZK Proof'}
          </p>
          <p className="text-[10px] text-gray-500 uppercase tracking-wider">
            Circuit: {proofType}
          </p>
        </div>
      </div>

      <div className="w-full h-1.5 bg-gray-800 rounded-full overflow-hidden mb-2">
        <div
          className={cn(
            'h-full rounded-full transition-all duration-500',
            isDone && 'bg-gradient-to-r from-emerald-500 to-emerald-400',
            isError && 'bg-gradient-to-r from-red-600 to-red-400',
            isActive && 'bg-gradient-to-r from-indigo-600 to-indigo-400',
          )}
          style={{ width: `${progress}%` }}
        />
      </div>

      <p
        className={cn(
          'text-[11px]',
          isDone && 'text-emerald-400',
          isError && 'text-red-400',
          isActive && 'text-gray-400',
        )}
      >
        {isError && error ? error : STAGE_LABELS[stage]}
      </p>
    </div>
  );
}
