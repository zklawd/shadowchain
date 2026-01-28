'use client';

import { useMemo } from 'react';
import { useReadContract, useReadContracts } from 'wagmi';
import { formatEther } from 'viem';
import { shadowChainGameConfig } from './contracts';

export interface GameStats {
  activeGames: string;
  totalPlayers: string;
  totalPot: string;
  proofsVerified: string;
}

const FALLBACK: GameStats = {
  activeGames: '—',
  totalPlayers: '—',
  totalPot: '—',
  proofsVerified: '—',
};

/**
 * Reads on-chain game data from ShadowChainGame and computes live stats
 * for the landing page: active games, players in active games, total prize pool,
 * and an estimate of ZK proofs verified (based on cumulative turns played).
 */
export function useGameStats(): { stats: GameStats; isLoading: boolean } {
  // 1. How many games exist?
  const { data: nextGameId, isLoading: loadingId } = useReadContract({
    ...shadowChainGameConfig,
    functionName: 'nextGameId',
  });

  const gameCount = nextGameId ? Number(nextGameId) : 0;

  // 2. Batch-read every game struct
  const gameContracts = useMemo(() => {
    if (gameCount <= 1) return []; // skip game #0 (phantom)
    return Array.from({ length: gameCount - 1 }, (_, i) => ({
      ...shadowChainGameConfig,
      functionName: 'getGame' as const,
      args: [BigInt(i + 1)] as const,
    }));
  }, [gameCount]);

  const { data: gamesData, isLoading: loadingGames } = useReadContracts({
    contracts: gameContracts,
    query: { enabled: gameCount > 0 },
  });

  // 3. Derive stats from raw game data
  const stats = useMemo<GameStats>(() => {
    // Still loading or contract returned nothing
    if (!gamesData) return FALLBACK;

    let activeCount = 0;
    let playerCount = 0;
    let totalPotWei = BigInt(0);
    let totalTurns = 0;

    for (const result of gamesData) {
      if (result.status !== 'success' || !result.result) continue;

      const g = result.result as {
        id: bigint;
        state: number;
        playerCount: number;
        prizePool: bigint;
        currentTurn: number;
        aliveCount: number;
      };

      // state: 0 = Waiting, 1 = Active, 2 = Ended
      if (g.state === 1) {
        activeCount++;
        playerCount += g.playerCount;
      }

      totalPotWei += g.prizePool;

      // Each turn advancement means at least one ZK proof was verified on-chain
      totalTurns += g.currentTurn;
    }

    const totalPotEth = parseFloat(formatEther(totalPotWei));
    const potDisplay =
      totalPotEth === 0
        ? '0 ETH'
        : totalPotEth < 0.001
          ? '<0.001 ETH'
          : `${totalPotEth.toFixed(totalPotEth < 1 ? 3 : 1)} ETH`;

    return {
      activeGames: activeCount.toString(),
      totalPlayers: playerCount.toString(),
      totalPot: potDisplay,
      proofsVerified: totalTurns > 0 ? totalTurns.toLocaleString() : '0',
    };
  }, [gamesData]);

  return {
    stats,
    isLoading: loadingId || loadingGames,
  };
}
