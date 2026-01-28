import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http, createStorage } from 'wagmi';
import { sepolia } from 'wagmi/chains';

// WalletConnect Cloud project ID
const WALLETCONNECT_PROJECT_ID =
  process.env.NEXT_PUBLIC_WC_PROJECT_ID || '1ff47d6e1976d616ee7d1a23857bfe94';

export const config = getDefaultConfig({
  appName: 'ShadowChain',
  projectId: WALLETCONNECT_PROJECT_ID,
  chains: [sepolia],
  transports: {
    [sepolia.id]: http('https://ethereum-sepolia-rpc.publicnode.com'),
  },
  ssr: false,
  // Use sessionStorage so each tab has independent wallet state
  // Fixes: same-browser multiplayer testing (each tab = different player)
  storage: createStorage({
    storage: typeof window !== 'undefined' ? window.sessionStorage : undefined,
  }),
});
