'use client';

import { useState, useRef, useEffect, useCallback } from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount, useConnect, useDisconnect } from 'wagmi';
import { type Hex } from 'viem';
import {
  IS_DEV_MODE,
  devWalletConnector,
  validatePrivateKey,
  addressFromKey,
  saveDevWalletKey,
  clearDevWalletKey,
} from '@/lib/dev-wallet';

// ── Dev Wallet Badge (shown when connected via dev key) ────

function DevBadge() {
  return (
    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-amber-500/10 border border-amber-500/30 rounded text-[10px] font-bold text-amber-400 tracking-wider animate-pulse">
      ⚠️ DEV
    </span>
  );
}

// ── Dev Wallet Popover ─────────────────────────────────────

function DevWalletPopover({
  onConnect,
  onClose,
}: {
  onConnect: (key: Hex) => void;
  onClose: () => void;
}) {
  const [keyInput, setKeyInput] = useState('');
  const [error, setError] = useState('');
  const [preview, setPreview] = useState('');
  const inputRef = useRef<HTMLInputElement>(null);
  const popoverRef = useRef<HTMLDivElement>(null);

  // Auto-focus the input
  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  // Close on outside click
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (popoverRef.current && !popoverRef.current.contains(e.target as Node)) {
        onClose();
      }
    }
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, [onClose]);

  // Close on Escape
  useEffect(() => {
    function handleKey(e: KeyboardEvent) {
      if (e.key === 'Escape') onClose();
    }
    document.addEventListener('keydown', handleKey);
    return () => document.removeEventListener('keydown', handleKey);
  }, [onClose]);

  // Validate on input change
  useEffect(() => {
    if (!keyInput.trim()) {
      setError('');
      setPreview('');
      return;
    }
    const validated = validatePrivateKey(keyInput);
    if (validated) {
      setError('');
      const addr = addressFromKey(validated);
      setPreview(`${addr.slice(0, 6)}…${addr.slice(-4)}`);
    } else {
      setError('Invalid private key');
      setPreview('');
    }
  }, [keyInput]);

  const handleSubmit = () => {
    const validated = validatePrivateKey(keyInput);
    if (!validated) {
      setError('Invalid private key (must be 64 hex chars)');
      return;
    }
    onConnect(validated);
  };

  return (
    <div
      ref={popoverRef}
      className="absolute right-0 top-full mt-2 w-80 bg-gray-900 border border-gray-700 rounded-lg shadow-2xl shadow-black/50 z-50 overflow-hidden"
    >
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-800 bg-gray-900/80">
        <div className="flex items-center gap-2">
          <span className="text-amber-400 text-sm">🔧</span>
          <span className="text-xs font-bold text-gray-300 tracking-wider">DEV WALLET</span>
        </div>
        <button
          onClick={onClose}
          className="text-gray-600 hover:text-gray-400 transition-colors text-lg leading-none"
        >
          ×
        </button>
      </div>

      {/* Body */}
      <div className="p-4 space-y-3">
        <p className="text-[11px] text-gray-500 leading-relaxed">
          Paste a private key to connect an in-memory wallet. Key is never stored — cleared on
          refresh.
        </p>

        {/* Input */}
        <div className="relative">
          <input
            ref={inputRef}
            type="password"
            value={keyInput}
            onChange={(e) => setKeyInput(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSubmit()}
            placeholder="0x..."
            autoComplete="off"
            spellCheck={false}
            className={`w-full px-3 py-2.5 bg-gray-950 border rounded-md text-sm font-mono text-gray-300 placeholder-gray-700 focus:outline-none transition-colors ${
              error
                ? 'border-red-500/50 focus:border-red-500'
                : 'border-gray-700 focus:border-emerald-500/50'
            }`}
          />
          {preview && (
            <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[10px] text-emerald-400/70 font-mono">
              {preview}
            </span>
          )}
        </div>

        {/* Error */}
        {error && <p className="text-[11px] text-red-400">{error}</p>}

        {/* Warning */}
        <div className="flex items-start gap-2 px-3 py-2 bg-amber-500/5 border border-amber-500/20 rounded text-[10px] text-amber-400/80 leading-relaxed">
          <span className="mt-0.5">⚠️</span>
          <span>Dev only. Never use a mainnet key here.</span>
        </div>

        {/* Submit */}
        <button
          onClick={handleSubmit}
          disabled={!keyInput.trim() || !!error}
          className="w-full py-2.5 bg-emerald-500/10 border border-emerald-500/40 text-emerald-400 text-xs font-bold tracking-wider rounded-md transition-all duration-200 hover:bg-emerald-500/20 hover:border-emerald-400/60 hover:shadow-[0_0_20px_rgba(16,185,129,0.1)] disabled:opacity-30 disabled:cursor-not-allowed disabled:hover:bg-emerald-500/10 disabled:hover:border-emerald-500/40 disabled:hover:shadow-none"
        >
          CONNECT DEV WALLET
        </button>
      </div>
    </div>
  );
}

// ── Main Component ─────────────────────────────────────────

export default function WalletConnect() {
  const [showDevPopover, setShowDevPopover] = useState(false);
  const [devConnecting, setDevConnecting] = useState(false);
  const { connector: activeConnector } = useAccount();
  const { connectAsync } = useConnect();
  const { disconnect } = useDisconnect();

  const isDevWallet = activeConnector?.id === 'dev-wallet';

  const handleDevConnect = useCallback(
    async (key: Hex) => {
      setDevConnecting(true);
      try {
        const connector = devWalletConnector({ privateKey: key });
        await connectAsync({ connector });
        // Persist key in sessionStorage so it survives navigation
        saveDevWalletKey(key);
        setShowDevPopover(false);
      } catch (err) {
        console.error('[Dev Wallet] Connection failed:', err);
      } finally {
        setDevConnecting(false);
      }
    },
    [connectAsync],
  );

  return (
    <ConnectButton.Custom>
      {({ account, chain, openAccountModal, openChainModal, openConnectModal, mounted }) => {
        const ready = mounted;
        const connected = ready && account && chain;

        return (
          <div
            className="flex items-center gap-2"
            {...(!ready && {
              'aria-hidden': true,
              style: {
                opacity: 0,
                pointerEvents: 'none' as const,
                userSelect: 'none' as const,
              },
            })}
          >
            {(() => {
              // ── Not connected ──────────────────────────
              if (!connected) {
                return (
                  <div className="relative flex items-center gap-2">
                    {/* Standard RainbowKit connect */}
                    <button
                      onClick={openConnectModal}
                      className="group relative px-6 py-3 border-2 border-emerald-500/50 bg-emerald-500/5 text-emerald-400 font-mono text-sm font-semibold rounded-lg transition-all duration-300 hover:border-emerald-400 hover:bg-emerald-500/15 hover:shadow-[0_0_30px_rgba(16,185,129,0.2)] active:scale-95"
                    >
                      <span className="relative z-10 flex items-center gap-2">
                        <svg
                          className="w-4 h-4"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth={2}
                            d="M13 10V3L4 14h7v7l9-11h-7z"
                          />
                        </svg>
                        Connect Wallet
                      </span>
                    </button>

                    {/* Dev wallet button (only in dev mode) */}
                    {IS_DEV_MODE && (
                      <button
                        onClick={() => setShowDevPopover((s) => !s)}
                        disabled={devConnecting}
                        className="px-3 py-3 border border-amber-500/30 bg-amber-500/5 text-amber-400 text-sm rounded-lg transition-all duration-200 hover:border-amber-400/50 hover:bg-amber-500/10 active:scale-95 disabled:opacity-50"
                        title="Dev Wallet — paste a private key"
                      >
                        🔧
                      </button>
                    )}

                    {/* Dev wallet popover */}
                    {showDevPopover && (
                      <DevWalletPopover
                        onConnect={handleDevConnect}
                        onClose={() => setShowDevPopover(false)}
                      />
                    )}
                  </div>
                );
              }

              // ── Wrong network ──────────────────────────
              if (chain.unsupported) {
                return (
                  <button
                    onClick={openChainModal}
                    className="px-5 py-2.5 border border-red-500/30 bg-red-500/10 text-red-400 font-mono text-sm rounded-lg transition-all duration-300 hover:border-red-400/60 hover:bg-red-500/20"
                  >
                    Wrong network
                  </button>
                );
              }

              // ── Connected ──────────────────────────────
              return (
                <div className="flex items-center gap-2">
                  {isDevWallet && <DevBadge />}
                  <button
                    onClick={openAccountModal}
                    className="group relative px-5 py-2.5 border border-emerald-500/30 bg-emerald-500/10 text-emerald-400 font-mono text-sm rounded-lg transition-all duration-300 hover:border-emerald-400/60 hover:bg-emerald-500/20 hover:shadow-[0_0_20px_rgba(16,185,129,0.15)]"
                  >
                    <span className="flex items-center gap-2">
                      <span
                        className={`w-2 h-2 rounded-full animate-pulse ${
                          isDevWallet ? 'bg-amber-400' : 'bg-emerald-400'
                        }`}
                      />
                      {account.displayName}
                    </span>
                  </button>
                </div>
              );
            })()}
          </div>
        );
      }}
    </ConnectButton.Custom>
  );
}
