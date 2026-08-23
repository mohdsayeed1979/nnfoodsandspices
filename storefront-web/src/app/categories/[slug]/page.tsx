import Link from 'next/link';
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { getCategoryBySlug, getProducts } from '@/lib/catalog';
import { ProductCard } from '@/components/ProductCard';
import { SortSelect } from '@/components/SortSelect';
import type { SortKey } from '@/lib/types';
import { siteUrl } from '@/lib/constants';

export const dynamic = 'force-dynamic';

const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
const PAGE_SIZE = 12;

export async function generateMetadata({
  params,
}: {
  params: { slug: string };
}): Promise<Metadata> {
  const category = await getCategoryBySlug(params.slug);
  if (!category) return { title: 'Category not found' };
  return {
    title: category.name,
    description: category.description || `Shop ${category.name} from NN Foods & Spices.`,
    alternates: { canonical: `/categories/${category.slug}` },
    openGraph: {
      title: `${category.name} — NN Foods & Spices`,
      description: category.description || `Shop ${category.name}.`,
      url: `${siteUrl()}/categories/${category.slug}`,
    },
  };
}

export default async function CategoryProductsPage({
  params,
  searchParams,
}: {
  params: { slug: string };
  searchParams: { [k: string]: string | string[] | undefined };
}) {
  const category = await getCategoryBySlug(params.slug);
  if (!category) notFound();

  const sort = (one(searchParams.sort) as SortKey) ?? 'featured';
  const page = Math.max(1, parseInt(one(searchParams.page) ?? '1', 10) || 1);
  const { products, total } = await getProducts({
    categorySlug: category.slug,
    sort,
    page,
    pageSize: PAGE_SIZE,
  });
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="container-x py-10">
      <nav className="text-xs text-gray-500">
        <Link href="/" className="hover:text-brand-greenDark">Home</Link> ·{' '}
        <Link href="/categories" className="hover:text-brand-greenDark">Categories</Link> ·{' '}
        <span className="text-gray-700">{category.name}</span>
      </nav>

      <div className="mt-4 flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-bold text-gray-900">{category.name}</h1>
          {category.description && <p className="mt-1 max-w-2xl text-sm text-gray-500">{category.description}</p>}
          <p className="mt-1 text-xs text-gray-400">{total} product{total === 1 ? '' : 's'}</p>
        </div>
        <SortSelect current={sort} />
      </div>

      {products.length === 0 ? (
        <div className="mt-16 text-center text-gray-500">No products in this category yet.</div>
      ) : (
        <div className="mt-8 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          {products.map((p) => (
            <ProductCard key={p.id} product={p} />
          ))}
        </div>
      )}

      {totalPages > 1 && (
        <div className="mt-10 flex items-center justify-center gap-2">
          {Array.from({ length: totalPages }).map((_, i) => {
            const n = i + 1;
            const p = new URLSearchParams();
            if (sort !== 'featured') p.set('sort', sort);
            if (n > 1) p.set('page', String(n));
            const href = p.toString()
              ? `/categories/${category.slug}?${p.toString()}`
              : `/categories/${category.slug}`;
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
