import Link from 'next/link';
import type { Metadata } from 'next';
import { getCategories, getProducts } from '@/lib/catalog';
import { ProductCard } from '@/components/ProductCard';
import { SortSelect } from '@/components/SortSelect';
import type { SortKey } from '@/lib/types';

export const dynamic = 'force-dynamic';

export const metadata: Metadata = {
  title: 'Products',
  description: 'Browse the full range of NN Foods & Spices — 100% naturally pure spices and masala blends.',
  alternates: { canonical: '/products' },
};

const PAGE_SIZE = 12;

type SP = { [k: string]: string | string[] | undefined };
const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);

function qs(base: SP, patch: Record<string, string | undefined>): string {
  const p = new URLSearchParams();
  for (const [k, v] of Object.entries(base)) {
    const val = one(v);
    if (val) p.set(k, val);
  }
  for (const [k, v] of Object.entries(patch)) {
    if (v === undefined) p.delete(k);
    else p.set(k, v);
  }
  p.delete('page');
  const s = p.toString();
  return s ? `/products?${s}` : '/products';
}

export default async function ProductsPage({ searchParams }: { searchParams: SP }) {
  const search = one(searchParams.search) ?? '';
  const categorySlug = one(searchParams.category) ?? '';
  const featured = one(searchParams.featured) === '1';
  const sort = (one(searchParams.sort) as SortKey) ?? 'featured';
  const page = Math.max(1, parseInt(one(searchParams.page) ?? '1', 10) || 1);

  const [categories, { products, total }] = await Promise.all([
    getCategories(),
    getProducts({ search, categorySlug, featured, sort, page, pageSize: PAGE_SIZE }),
  ]);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="container-x py-10">
      <h1 className="font-display text-3xl font-bold text-gray-900">Our Products</h1>
      <p className="mt-1 text-sm text-gray-500">
        {total} product{total === 1 ? '' : 's'}
        {search ? ` matching “${search}”` : ''}
      </p>

      {/* Search (GET form) */}
      <form action="/products" className="mt-6 flex gap-2" method="get">
        {categorySlug && <input type="hidden" name="category" value={categorySlug} />}
        {featured && <input type="hidden" name="featured" value="1" />}
        <input
          type="search"
          name="search"
          defaultValue={search}
          placeholder="Search by name or SKU…"
          className="input max-w-md"
        />
        <button type="submit" className="btn-primary">Search</button>
      </form>

      {/* Filters */}
      <div className="mt-5 flex flex-wrap items-center gap-2">
        <Link
          href={qs(searchParams, { category: undefined })}
          className={`chip ${!categorySlug ? 'bg-brand-green text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}
        >
          All
        </Link>
        {categories.map((c) => (
          <Link
            key={c.id}
            href={qs(searchParams, { category: c.slug })}
            className={`chip ${categorySlug === c.slug ? 'bg-brand-green text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}
          >
            {c.name}
          </Link>
        ))}
        <Link
          href={qs(searchParams, { featured: featured ? undefined : '1' })}
          className={`chip ${featured ? 'bg-brand-orange text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}
        >
          ★ Featured
        </Link>
        <div className="ml-auto">
          <SortSelect current={sort} />
        </div>
      </div>

      {/* Grid */}
      {products.length === 0 ? (
        <div className="mt-16 text-center text-gray-500">
          No products found. Try a different search or category.
        </div>
      ) : (
        <div className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          {products.map((p) => (
            <ProductCard key={p.id} product={p} />
          ))}
        </div>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="mt-10 flex items-center justify-center gap-2">
          {Array.from({ length: totalPages }).map((_, i) => {
            const n = i + 1;
            const p = new URLSearchParams();
            for (const [k, v] of Object.entries(searchParams)) {
              const val = one(v);
              if (val && k !== 'page') p.set(k, val);
            }
            if (n > 1) p.set('page', String(n));
            const href = p.toString() ? `/products?${p.toString()}` : '/products';
            return (
              <Link
                key={n}
                href={href}
                className={`flex h-9 w-9 items-center justify-center rounded-full text-sm font-semibold ${
                  n === page ? 'bg-brand-green text-white' : 'border border-gray-300 text-gray-700 hover:bg-gray-50'
                }`}
              >
                {n}
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
