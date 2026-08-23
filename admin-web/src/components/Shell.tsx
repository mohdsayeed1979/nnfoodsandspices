'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { BrandWordmark } from './Brand';

const NAV = [
  { href: '/admin/dashboard', label: 'Dashboard', icon: '▦' },
  { href: '/admin/products', label: 'Products', icon: '🌶' },
  { href: '/admin/categories', label: 'Categories', icon: '🗂' },
];

export function Shell({
  adminEmail,
  children,
}: {
  adminEmail: string;
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);

  const title = NAV.find((n) => pathname.startsWith(n.href))?.label ?? 'Admin';

  const sidebar = (
    <nav className="flex h-full flex-col">
      <div className="border-b border-gray-200 px-5 py-4">
        <BrandWordmark />
      </div>
      <div className="flex-1 space-y-1 p-3">
        {NAV.map((n) => {
          const active = pathname.startsWith(n.href);
          return (
            <Link
              key={n.href}
              href={n.href}
              onClick={() => setOpen(false)}
              className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition ${
                active
                  ? 'bg-brand-green/10 text-brand-greenDark'
                  : 'text-gray-600 hover:bg-gray-100'
              }`}
            >
              <span className="text-base">{n.icon}</span>
              {n.label}
            </Link>
          );
        })}
      </div>
      <form action="/auth/signout" method="post" className="border-t border-gray-200 p-3">
        <button type="submit" className="btn-secondary w-full !justify-start text-red-600">
          ⎋ Logout
        </button>
      </form>
    </nav>
  );

  return (
    <div className="flex min-h-screen">
      {/* Desktop sidebar */}
      <aside className="hidden w-64 shrink-0 border-r border-gray-200 bg-white md:block">
        {sidebar}
      </aside>

      {/* Mobile drawer */}
      {open && (
        <div className="fixed inset-0 z-40 md:hidden">
          <div className="absolute inset-0 bg-black/40" onClick={() => setOpen(false)} />
          <aside className="absolute left-0 top-0 h-full w-64 bg-white shadow-xl">{sidebar}</aside>
        </div>
      )}

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-30 flex items-center justify-between border-b border-gray-200 bg-white px-4 py-3">
          <div className="flex items-center gap-3">
            <button
              className="rounded-lg border border-gray-300 px-2.5 py-1.5 text-gray-600 md:hidden"
              onClick={() => setOpen(true)}
              aria-label="Open menu"
            >
              ☰
            </button>
            <h1 className="text-lg font-bold text-gray-900">{title}</h1>
          </div>
          <div className="flex items-center gap-3">
            <span className="hidden text-sm text-gray-500 sm:inline">{adminEmail}</span>
            <form action="/auth/signout" method="post">
              <button type="submit" className="text-sm font-semibold text-red-600 hover:underline">
                Logout
              </button>
            </form>
          </div>
        </header>

        <main className="flex-1 p-4 md:p-6">{children}</main>
      </div>
    </div>
  );
}
