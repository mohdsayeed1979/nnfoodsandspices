import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="container-x flex min-h-[50vh] flex-col items-center justify-center py-20 text-center">
      <div className="font-display text-6xl font-extrabold text-brand-green">404</div>
      <h1 className="mt-2 text-xl font-bold text-gray-900">Page not found</h1>
      <p className="mt-1 text-sm text-gray-500">The page you&apos;re looking for doesn&apos;t exist.</p>
      <div className="mt-6 flex gap-3">
        <Link href="/" className="btn-primary">Go Home</Link>
        <Link href="/products" className="btn-outline">Browse Products</Link>
      </div>
    </div>
  );
}
