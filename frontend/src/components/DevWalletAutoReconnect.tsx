'use client';

/**
 * DevWalletAutoReconnect — restores a dev wallet from sessionStorage on mount.
 *
 * When the user connects a dev wallet, the private key is stored in
 * sessionStorage (tab-scoped, cleared on tab close). On Next.js client-side
 * navigation or page mount, this component checks for a stored key and
 * silently reconnects the dev wallet connector.
 *
 * On explicit disconnect (isConnected goes false after we auto-reconnected),
 * the stored key is cleared so it won't reconnect again.
 */

import { useEffect, useRef } from 'react';
import { useAccount, useConnect } from 'wagmi';
import {
  IS_DEV_MODE,
  loadDevWalletKey,
  clearDevWalletKey,
  devWalletConnector,
} from '@/lib/dev-wallet';

export default function DevWalletAutoReconnect() {
  const { isConnected, connector } = useAccount();
  const { connectAsync } = useConnect();

  // Track whether we performed an auto-reconnect this session
  const didAutoReconnect = useRef(false);
  // Track the previous connected state to detect disconnect transitions
  const wasConnected = useRef(false);
  // Prevent double-fire in StrictMode
  const reconnecting = useRef(false);

  // ── Auto-reconnect on mount ────────────────────────
  useEffect(() => {
    if (!IS_DEV_MODE) return;
    if (isConnected) return; // Already connected, nothing to do
    if (reconnecting.current) return;

    const storedKey = loadDevWalletKey();
    if (!storedKey) return;

    reconnecting.current = true;

    (async () => {
      try {
        const conn = devWalletConnector({ privateKey: storedKey });
        await connectAsync({ connector: conn });
        didAutoReconnect.current = true;
        console.log('[Dev Wallet] Auto-reconnected from sessionStorage');
      } catch (err) {
        console.warn('[Dev Wallet] Auto-reconnect failed, clearing key:', err);
        clearDevWalletKey();
      } finally {
        reconnecting.current = false;
      }
    })();
  }, [isConnected, connectAsync]);

  // ── Clear sessionStorage on explicit disconnect ────
  useEffect(() => {
    if (isConnected) {
      wasConnected.current = true;
    } else if (wasConnected.current && didAutoReconnect.current) {
      // Transitioned from connected → disconnected after an auto-reconnect.
      // This means the user explicitly disconnected.
      clearDevWalletKey();
      didAutoReconnect.current = false;
      wasConnected.current = false;
      console.log('[Dev Wallet] Cleared sessionStorage on disconnect');
    }
  }, [isConnected]);

  // Also clear on manual disconnect when user was connected via dev wallet
  // (covers the case where they connected manually this session, not via auto-reconnect)
  useEffect(() => {
    if (!isConnected && wasConnected.current && connector?.id !== 'dev-wallet') {
      // Non-dev-wallet disconnect, just reset tracking
      wasConnected.current = false;
    }
  }, [isConnected, connector]);

  return null; // Renderless component
}
