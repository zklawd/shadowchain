import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http } from 'wagmi';
import { sepolia } from 'wagmi/chains';

// WalletConnect Cloud project ID
// Set NEXT_PUBLIC_WC_PROJECT_ID in .env.local for real WC support.
// The fallback is a format-valid placeholder so the build doesn't crash;
// WalletConnect modal won't work until a real ID is supplied, but
// injected wallets (MetaMask, Rabby, etc.) work fine without it.
const WALLETCONNECT_PROJECT_ID =
  process.env.NEXT_PUBLIC_WC_PROJECT_ID || '0'.repeat(32);

export const config = getDefaultConfig({
  appName: 'ShadowChain',
  projectId: WALLETCONNECT_PROJECT_ID,
  chains: [sepolia],
  transports: {
    [sepolia.id]: http('https://ethereum-sepolia-rpc.publicnode.com'),
  },
  ssr: true,
});
