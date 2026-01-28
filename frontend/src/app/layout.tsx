import type { Metadata } from 'next';
import './globals.css';
import Providers from '@/components/Providers';

export const metadata: Metadata = {
  title: 'ShadowChain — ZK Fog-of-War Arena',
  description: 'Move in shadow. Strike with proof. A multiplayer on-chain strategy game with zero-knowledge proofs.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className="font-mono antialiased bg-gray-950 text-gray-200 crt-overlay">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
