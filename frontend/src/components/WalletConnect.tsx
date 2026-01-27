'use client';

import { useState } from 'react';
import { truncateAddress } from '@/lib/utils';

// Mock wallet connection (will be replaced with wagmi + RainbowKit)
export default function WalletConnect() {
  const [connected, setConnected] = useState(false);
  const [address, setAddress] = useState('');

  const handleConnect = () => {
    setConnected(true);
    setAddress('0x1234567890abcdef1234567890abcdef12345678');
  };

  const handleDisconnect = () => {
    setConnected(false);
    setAddress('');
  };

  if (connected) {
    return (
      <button
        onClick={handleDisconnect}
        className="group relative px-6 py-3 border border-emerald-500/30 bg-emerald-500/10 
                   text-emerald-400 font-mono text-sm rounded-lg transition-all duration-300
                   hover:border-emerald-400/60 hover:bg-emerald-500/20 hover:shadow-[0_0_20px_rgba(16,185,129,0.2)]"
      >
        <span className="flex items-center gap-2">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          {truncateAddress(address)}
        </span>
      </button>
    );
  }

  return (
    <button
      onClick={handleConnect}
      className="group relative px-8 py-4 border-2 border-emerald-500/50 bg-emerald-500/5 
                 text-emerald-400 font-mono text-base font-semibold rounded-lg transition-all duration-300
                 hover:border-emerald-400 hover:bg-emerald-500/15 hover:shadow-[0_0_30px_rgba(16,185,129,0.3)]
                 active:scale-95"
    >
      <span className="relative z-10 flex items-center gap-3">
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} 
                d="M13 10V3L4 14h7v7l9-11h-7z" />
        </svg>
        Connect Wallet
      </span>
      <div className="absolute inset-0 rounded-lg bg-gradient-to-r from-emerald-500/0 via-emerald-500/5 to-emerald-500/0 
                      opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
    </button>
  );
}
