'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiProvider } from 'wagmi';
import { RainbowKitProvider, darkTheme } from '@rainbow-me/rainbowkit';
import { config } from '@/lib/wagmi';
import '@rainbow-me/rainbowkit/styles.css';

const queryClient = new QueryClient();

const customTheme = darkTheme({
  accentColor: '#10b981', // emerald-500
  accentColorForeground: '#022c22', // emerald-950
  borderRadius: 'medium',
  fontStack: 'system',
});

// Override specific colors to match the dark/emerald theme
const theme = {
  ...customTheme,
  colors: {
    ...customTheme.colors,
    modalBackground: '#111827', // gray-900
    modalBorder: '#1f2937', // gray-800
    profileForeground: '#111827',
    generalBorder: '#374151', // gray-700
    menuItemBackground: '#1f2937',
    connectButtonBackground: 'transparent',
    connectButtonInnerBackground: 'rgba(16, 185, 129, 0.1)',
    connectButtonText: '#34d399', // emerald-400
  },
};

export default function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider theme={theme} modalSize="compact">
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
