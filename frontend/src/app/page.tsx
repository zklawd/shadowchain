'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import WalletConnect from '@/components/WalletConnect';
import { useGameStats } from '@/lib/useGameStats';

const GLITCH_CHARS = '01アイウエオカキクケコ█▓▒░';

export default function LandingPage() {
  const [title, setTitle] = useState('ShadowChain');
  const [mounted, setMounted] = useState(false);
  const { stats, isLoading: statsLoading } = useGameStats();

  useEffect(() => { setMounted(true); }, []);

  /* Glitch-decode title on mount */
  useEffect(() => {
    if (!mounted) return;
    const target = 'ShadowChain';
    let frame = 0;
    const id = setInterval(() => {
      setTitle(
        target
          .split('')
          .map((ch, i) =>
            i < frame ? ch : GLITCH_CHARS[Math.floor(Math.random() * GLITCH_CHARS.length)]
          )
          .join('')
      );
      frame += 0.5;
      if (frame > target.length) { clearInterval(id); setTitle(target); }
    }, 35);
    return () => clearInterval(id);
  }, [mounted]);

  return (
    <div className="min-h-screen flex flex-col relative overflow-hidden">
      {/* Background grid */}
      <div
        className="absolute inset-0 opacity-[0.03]"
        style={{
          backgroundImage:
            'linear-gradient(rgba(16,185,129,.3) 1px,transparent 1px),' +
            'linear-gradient(90deg,rgba(16,185,129,.3) 1px,transparent 1px)',
          backgroundSize: '48px 48px',
        }}
      />
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(16,185,129,0.06)_0%,transparent_70%)]" />

      {/* Particles */}
      {mounted &&
        Array.from({ length: 16 }, (_, i) => (
          <div
            key={i}
            className="absolute w-1 h-1 bg-emerald-500/20 rounded-full"
            style={{
              left: `${6 + i * 6}%`,
              top: `${10 + (i * 37) % 80}%`,
              animation: `float-particle ${8 + (i % 5) * 3}s ease-in-out infinite`,
              animationDelay: `${(i * 0.7) % 4}s`,
            }}
          />
        ))}

      {/* Header */}
      <header className="relative z-10 flex items-center justify-between px-8 py-6">
        <div className="flex items-center gap-2 text-emerald-400">
          <span className="text-lg">◆</span>
          <span className="text-xs font-bold tracking-[0.25em] text-gray-400">SHADOWCHAIN</span>
        </div>
        <WalletConnect />
      </header>

      {/* Hero */}
      <main className="relative z-10 flex-1 flex flex-col items-center justify-center px-8 -mt-12">
        <div className="text-center max-w-3xl">
          {/* Badge */}
          <div className="animate-fade-in-up mb-8" style={{ animationDelay: '0.1s', opacity: 0 }}>
            <span className="inline-flex items-center gap-2 px-4 py-1.5 border border-emerald-500/20 bg-emerald-500/5 rounded-full text-[11px] text-emerald-400 tracking-wider">
              <span className="w-1.5 h-1.5 bg-emerald-400 rounded-full animate-pulse" />
              ZK Fog-of-War Arena · Testnet
            </span>
          </div>

          {/* Title */}
          <h1
            className="text-6xl sm:text-7xl md:text-8xl font-extrabold tracking-tighter mb-6 animate-fade-in-up bg-clip-text text-transparent bg-gradient-to-b from-white via-gray-200 to-gray-500 leading-[1.1]"
            style={{ animationDelay: '0.2s', opacity: 0 }}
          >
            {title}
          </h1>

          {/* Tagline */}
          <p
            className="text-lg sm:text-xl md:text-2xl text-gray-400 mb-3 animate-fade-in-up tracking-wide"
            style={{ animationDelay: '0.35s', opacity: 0 }}
          >
            Move in shadow. Strike with proof.
          </p>
          <p
            className="text-sm text-gray-600 mb-12 max-w-md mx-auto animate-fade-in-up leading-relaxed"
            style={{ animationDelay: '0.45s', opacity: 0 }}
          >
            A multiplayer on-chain strategy game where every move is hidden
            and every action is verified by zero-knowledge proofs.
          </p>

          {/* CTA */}
          <div
            className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-20 animate-fade-in-up"
            style={{ animationDelay: '0.55s', opacity: 0 }}
          >
            <Link
              href="/lobby"
              className="group px-10 py-4 bg-emerald-500/10 border-2 border-emerald-500/50 text-emerald-400 font-semibold rounded-lg transition-all duration-300 hover:bg-emerald-500/20 hover:border-emerald-400 hover:shadow-[0_0_40px_rgba(16,185,129,0.15)] active:scale-95"
            >
              <span className="flex items-center gap-3">
                Enter Arena
                <svg className="w-4 h-4 transition-transform group-hover:translate-x-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                </svg>
              </span>
            </Link>
            <a
              href="#rules"
              className="px-10 py-4 border border-gray-700 text-gray-400 font-semibold rounded-lg transition-all duration-300 hover:border-gray-500 hover:text-gray-300"
            >
              How It Works
            </a>
          </div>

          {/* Stats */}
          <div
            className="flex items-center justify-center gap-8 sm:gap-12 animate-fade-in-up"
            style={{ animationDelay: '0.65s', opacity: 0 }}
          >
            {[
              { label: 'Active Games', value: statsLoading ? '—' : stats.activeGames },
              { label: 'Players Online', value: statsLoading ? '—' : stats.totalPlayers },
              { label: 'Total Pot', value: statsLoading ? '—' : stats.totalPot },
              { label: 'Proofs Verified', value: statsLoading ? '—' : stats.proofsVerified },
            ].map((s) => (
              <div key={s.label} className="text-center">
                <div className="text-lg sm:text-xl font-bold text-white">{s.value}</div>
                <div className="text-[9px] text-gray-600 uppercase tracking-[0.2em]">{s.label}</div>
              </div>
            ))}
          </div>
        </div>
      </main>

      {/* Rules Section */}
      <section id="rules" className="relative z-10 px-8 py-24 border-t border-gray-800/40">
        <div className="max-w-5xl mx-auto">
          <h2 className="text-2xl sm:text-3xl font-bold text-center mb-3 text-white">How It Works</h2>
          <p className="text-center text-gray-500 mb-16 text-sm">Four phases of shadow warfare</p>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
            {([
              { icon: '◆', ic: 'text-indigo-400', bc: 'border-indigo-500/20', t: 'Join', d: 'Stake your entry fee and commit to a secret starting position using a cryptographic hash.', z: 'hash(x, y, salt)' },
              { icon: '◎', ic: 'text-emerald-400', bc: 'border-emerald-500/20', t: 'Explore', d: 'Navigate a 16×16 dungeon. Your position is hidden — only you can see where you are.', z: 'valid adjacent move' },
              { icon: '✦', ic: 'text-amber-400', bc: 'border-amber-500/20', t: 'Collect', d: "Claim artifacts at treasure cells to boost your stats. Nobody knows what you've found.", z: 'at treasure cell' },
              { icon: '⚔', ic: 'text-red-400', bc: 'border-red-500/20', t: 'Fight', d: 'When two shadows collide, combat triggers. Stats are revealed only for that battle.', z: 'stats + position' },
            ] as const).map((s, i) => (
              <div
                key={s.t}
                className={`bg-gray-900/50 border ${s.bc} rounded-lg p-6 hover:bg-gray-900/80 transition-all duration-300`}
              >
                <div className="flex items-center gap-3 mb-4">
                  <span className="text-[10px] text-gray-700 font-bold">{String(i + 1).padStart(2, '0')}</span>
                  <span className={`text-2xl ${s.ic}`}>{s.icon}</span>
                </div>
                <h3 className="text-base font-bold text-white mb-2">{s.t}</h3>
                <p className="text-sm text-gray-400 mb-4 leading-relaxed">{s.d}</p>
                <span className="text-[10px] text-gray-600 border border-gray-800 rounded px-2 py-1 inline-block">
                  ZK proof: {s.z}
                </span>
              </div>
            ))}
          </div>

          {/* Tech pills */}
          <div className="mt-14 flex flex-wrap justify-center gap-2">
            {['Noir Circuits', 'UltraHonk Proofs', 'Solidity', 'In-Browser Proving', 'Ethereum Sepolia'].map((t) => (
              <span key={t} className="text-[10px] text-gray-600 px-3 py-1 border border-gray-800 rounded-full">{t}</span>
            ))}
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="relative z-10 border-t border-gray-800/40 px-8 py-8">
        <div className="max-w-5xl mx-auto flex items-center justify-between text-xs text-gray-600">
          <span className="flex items-center gap-2">
            <span className="text-emerald-500">◆</span> ShadowChain
          </span>
          <span>Move in shadow. Strike with proof.</span>
        </div>
      </footer>
    </div>
  );
}
