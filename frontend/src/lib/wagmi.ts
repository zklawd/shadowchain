import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http } from 'wagmi';
import { sepolia } from 'wagmi/chains';

// WalletConnect Cloud project ID
// Get yours free at https://cloud.walletconnect.com
// Without a real ID, WalletConnect-based wallets won't work,
// but injected wallets (MetaMask, Rabby, etc.) work fine.
const WALLETCONNECT_PROJECT_ID =
  process.env.NEXT_PUBLIC_WC_PROJECT_ID || '0'.repeat(32);

export const config = getDefaultConfig({
  appName: 'ShadowChain',
  projectId: WALLETCONNECT_PROJECT_ID,
  chains: [sepolia],
  transports: {
    [sepolia.id]: http('https://ethereum-sepolia-rpc.publicnode.com'),
  },
  // ssr must be false for static export (output: 'export')
  ssr: false,
});
