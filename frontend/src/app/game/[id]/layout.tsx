// Static params for export mode
export function generateStaticParams() {
  return Array.from({ length: 50 }, (_, i) => ({ id: String(i + 1) }));
}

export default function GameLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
