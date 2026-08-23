'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Logo } from './Brand';

const NAV = [
  { href: '/', label: 'Home' },
  { href: '/products', label: 'Products' },
  { href: '/categories', label: 'Categories' },
  { href: '/about', label: 'About' },
  { href: '/contact', label: 'Contact' },
];

export function Header() {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState('');

  function search(e: React.FormEvent) {
    e.preventDefault();
    const term = q.trim();
    setOpen(false);
    router.push(term ? `/products?search=${encodeURIComponent(term)}` : '/products');
  }

  return (
    <header className="sticky top-0 z-50 border-b border-gray-100 bg-white/90 backdrop-blur">
      <div className="container-x flex h-16 items-center justify-between gap-4">
        <Logo />

        <nav className="hidden items-center gap-6 md:flex">
          {NAV.map((n) => (
            <Link
              key={n.href}
              href={n.href}
              className="text-sm font-medium text-gray-600 transition hover:text-brand-greenDark"
            >
              {n.label}
            </Link>
          ))}
        </nav>

        <div className="flex items-center gap-2">
          <form onSubmit={search} className="hidden sm:block">
            <input
              className="input w-44 lg:w-56"
              placeholder="Search spices…"
              value={q}
              onChange={(e) => setQ(e.target.value)}
              aria-label="Search products"
            />
          </form>
          <button
            className="rounded-lg border border-gray-200 p-2 text-gray-600 md:hidden"
            onClick={() => setOpen((o) => !o)}
            aria-label="Toggle menu"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              {open ? <path d="M6 6l12 12M18 6L6 18" /> : <path d="M4 7h16M4 12h16M4 17h16" />}
            </svg>
          </button>
        </div>
      </div>

      {open && (
        <div className="border-t border-gray-100 bg-white md:hidden">
          <div className="container-x space-y-1 py-3">
            <form onSubmit={search} className="pb-2">
              <input
                className="input"
                placeholder="Search spices…"
                value={q}
                onChange={(e) => setQ(e.target.value)}
              />
            </form>
            {NAV.map((n) => (
              <Link
                key={n.href}
                href={n.href}
                onClick={() => setOpen(false)}
                className="block rounded-lg px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                {n.label}
              </Link>
            ))}
          </div>
        </div>
      )}
    </header>
  );
}
