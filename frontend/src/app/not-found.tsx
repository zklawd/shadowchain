import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-950 text-gray-200">
      <div className="text-6xl mb-4 opacity-20">◆</div>
      <h1 className="text-2xl font-bold mb-2">Lost in the shadows</h1>
      <p className="text-gray-500 text-sm mb-6">This path leads nowhere.</p>
      <Link
        href="/"
        className="px-6 py-3 border border-emerald-500/40 text-emerald-400 text-sm rounded-lg hover:bg-emerald-500/10 transition-all"
      >
        Return to Base
      </Link>
    </div>
  );
}
