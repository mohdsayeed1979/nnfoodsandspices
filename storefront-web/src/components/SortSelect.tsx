'use client';

import { useRouter, useSearchParams } from 'next/navigation';

const OPTIONS: { value: string; label: string }[] = [
  { value: 'featured', label: 'Featured' },
  { value: 'newest', label: 'Newest' },
  { value: 'price-asc', label: 'Price: Low to High' },
  { value: 'price-desc', label: 'Price: High to Low' },
  { value: 'name', label: 'Name: A–Z' },
];

export function SortSelect({ current }: { current: string }) {
  const router = useRouter();
  const params = useSearchParams();

  function onChange(e: React.ChangeEvent<HTMLSelectElement>) {
    const p = new URLSearchParams(params.toString());
    p.set('sort', e.target.value);
    p.delete('page');
    router.push(`/products?${p.toString()}`);
  }

  return (
    <select
      aria-label="Sort products"
      value={current}
      onChange={onChange}
      className="rounded-full border border-gray-300 bg-white px-4 py-2 text-sm outline-none focus:border-brand-green"
    >
      {OPTIONS.map((o) => (
        <option key={o.value} value={o.value}>
          {o.label}
        </option>
      ))}
    </select>
  );
}
