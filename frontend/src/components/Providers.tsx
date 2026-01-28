'use client';

import { useState, useEffect } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiProvider } from 'wagmi';
import { RainbowKitProvider, darkTheme } from '@rainbow-me/rainbowkit';
import { config } from '@/lib/wagmi';
import DevWalletAutoReconnect from '@/components/DevWalletAutoReconnect';
import '@rainbow-me/rainbowkit/styles.css';

const customTheme = darkTheme({
  accentColor: '#10b981',
  accentColorForeground: '#022c22',
  borderRadius: 'medium',
  fontStack: 'system',
});

const theme = {
  ...customTheme,
  colors: {
    ...customTheme.colors,
    modalBackground: '#111827',
    modalBorder: '#1f2937',
    profileForeground: '#111827',
    generalBorder: '#374151',
    menuItemBackground: '#1f2937',
    connectButtonBackground: 'transparent',
    connectButtonInnerBackground: 'rgba(16, 185, 129, 0.1)',
    connectButtonText: '#34d399',
  },
};

export default function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient());
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider theme={theme} modalSize="compact">
          <DevWalletAutoReconnect />
          {mounted ? children : null}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
