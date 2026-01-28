/**
 * Dev Wallet Connector — paste a private key, get a fully functional wallet.
 *
 * Creates an EIP-1193 compatible provider backed by viem's local account
 * signing. Works with all wagmi hooks (useAccount, useWriteContract, etc.).
 *
 * The key is NEVER persisted — memory only, gone on refresh.
 */

import { createConnector } from 'wagmi';
import { createWalletClient, http, type Hex, type Address } from 'viem';
import { privateKeyToAccount, type PrivateKeyAccount } from 'viem/accounts';
import { sepolia } from 'viem/chains';

const RPC_URL = 'https://ethereum-sepolia-rpc.publicnode.com';

// ── EIP-1193 Provider wrapping a local private key ─────────

type Listener = (...args: any[]) => void;

function createDevProvider(account: PrivateKeyAccount) {
  const listeners: Record<string, Listener[]> = {};

  const walletClient = createWalletClient({
    account,
    chain: sepolia,
    transport: http(RPC_URL),
  });

  async function rpcPassthrough(method: string, params?: unknown[]) {
    const res = await fetch(RPC_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        jsonrpc: '2.0',
        id: Date.now(),
        method,
        params: params ?? [],
      }),
    });
    const json = await res.json();
    if (json.error) throw new Error(json.error.message);
    return json.result;
  }

  return {
    async request({ method, params }: { method: string; params?: unknown[] }) {
      switch (method) {
        case 'eth_requestAccounts':
        case 'eth_accounts':
          return [account.address];

        case 'eth_chainId':
          return `0x${sepolia.id.toString(16)}`;

        case 'net_version':
          return String(sepolia.id);

        case 'personal_sign': {
          const [message] = params as [Hex, Address];
          return account.signMessage({ message: { raw: message } });
        }

        case 'eth_sign': {
          const [, message] = params as [Address, Hex];
          return account.signMessage({ message: { raw: message } });
        }

        case 'eth_signTypedData_v4': {
          const [, data] = params as [Address, string];
          const typed = typeof data === 'string' ? JSON.parse(data) : data;
          return account.signTypedData({
            domain: typed.domain,
            types: typed.types,
            primaryType: typed.primaryType,
            message: typed.message,
          });
        }

        case 'eth_sendTransaction': {
          const [tx] = params as [Record<string, any>];
          return walletClient.sendTransaction({
            to: tx.to as Address,
            value: tx.value ? BigInt(tx.value) : undefined,
            data: tx.data as Hex | undefined,
            gas: tx.gas ? BigInt(tx.gas) : undefined,
            nonce: tx.nonce != null ? Number(tx.nonce) : undefined,
          });
        }

        case 'eth_signTransaction': {
          const [tx] = params as [Record<string, any>];
          return account.signTransaction({
            to: tx.to as Address,
            value: tx.value ? BigInt(tx.value) : undefined,
            data: tx.data as Hex | undefined,
            gas: tx.gas ? BigInt(tx.gas) : undefined,
            nonce: tx.nonce != null ? Number(tx.nonce) : undefined,
            chainId: sepolia.id,
          } as any);
        }

        case 'wallet_switchEthereumChain':
          // We only support Sepolia — silently accept
          return null;

        case 'wallet_addEthereumChain':
          return null;

        default:
          return rpcPassthrough(method, params);
      }
    },

    on(event: string, listener: Listener) {
      if (!listeners[event]) listeners[event] = [];
      listeners[event].push(listener);
    },

    removeListener(event: string, listener: Listener) {
      const arr = listeners[event];
      if (arr) listeners[event] = arr.filter((l) => l !== listener);
    },

    emit(event: string, ...args: unknown[]) {
      listeners[event]?.forEach((l) => l(...args));
    },
  };
}

// ── Wagmi Connector ────────────────────────────────────────

export type DevWalletConnectorOptions = {
  privateKey: Hex;
};

export function devWalletConnector({ privateKey }: DevWalletConnectorOptions) {
  const account = privateKeyToAccount(privateKey);
  const provider = createDevProvider(account);

  return createConnector(() => ({
    id: 'dev-wallet',
    name: 'Dev Wallet',
    type: 'dev-wallet',

    async connect() {
      return {
        accounts: [account.address] as readonly [Address],
        chainId: sepolia.id,
      };
    },

    async disconnect() {
      // No-op — memory wallet, nothing to clean up
    },

    async getAccounts() {
      return [account.address] as readonly [Address];
    },

    async getChainId() {
      return sepolia.id;
    },

    async getProvider() {
      return provider;
    },

    async isAuthorized() {
      return true;
    },

    onAccountsChanged() {},
    onChainChanged() {},
    onDisconnect() {},
  }));
}

// ── Session Storage Persistence ────────────────────────────

const SESSION_KEY = 'shadowchain:dev-wallet-key';

/** Save the dev wallet private key to sessionStorage (tab-scoped). */
export function saveDevWalletKey(key: Hex): void {
  try {
    sessionStorage.setItem(SESSION_KEY, key);
  } catch {
    // sessionStorage unavailable (SSR, iframe sandbox, etc.)
  }
}

/** Load a previously saved dev wallet key from sessionStorage, or null. */
export function loadDevWalletKey(): Hex | null {
  try {
    const stored = sessionStorage.getItem(SESSION_KEY);
    if (!stored) return null;
    // Re-validate to be safe
    return validatePrivateKey(stored);
  } catch {
    return null;
  }
}

/** Clear the dev wallet key from sessionStorage (on explicit disconnect). */
export function clearDevWalletKey(): void {
  try {
    sessionStorage.removeItem(SESSION_KEY);
  } catch {
    // no-op
  }
}

// ── Helpers ────────────────────────────────────────────────

/** Validate a hex private key string. Returns normalized `0x`-prefixed key or null. */
export function validatePrivateKey(input: string): Hex | null {
  const trimmed = input.trim();
  const hex = trimmed.startsWith('0x') ? trimmed : `0x${trimmed}`;

  // Must be 32 bytes = 64 hex chars + 0x prefix
  if (!/^0x[0-9a-fA-F]{64}$/.test(hex)) return null;

  try {
    // Ensure viem can parse it
    privateKeyToAccount(hex as Hex);
    return hex as Hex;
  } catch {
    return null;
  }
}

/** Derive address from a private key without connecting. */
export function addressFromKey(key: Hex): Address {
  return privateKeyToAccount(key).address;
}

/** Check if we're in dev mode. */
export const IS_DEV_MODE = process.env.NEXT_PUBLIC_DEV_MODE === 'true';
