'use client';

import { useState } from 'react';
import { truncateAddress } from '@/lib/utils';

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
        className="group relative px-5 py-2.5 border border-emerald-500/30 bg-emerald-500/10 text-emerald-400 font-mono text-sm rounded-lg transition-all duration-300 hover:border-emerald-400/60 hover:bg-emerald-500/20 hover:shadow-[0_0_20px_rgba(16,185,129,0.15)]"
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
      className="group relative px-6 py-3 border-2 border-emerald-500/50 bg-emerald-500/5 text-emerald-400 font-mono text-sm font-semibold rounded-lg transition-all duration-300 hover:border-emerald-400 hover:bg-emerald-500/15 hover:shadow-[0_0_30px_rgba(16,185,129,0.2)] active:scale-95"
    >
      <span className="relative z-10 flex items-center gap-2">
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
        </svg>
        Connect Wallet
      </span>
    </button>
  );
}
