import Link from 'next/link';
import { createClient } from '@/lib/supabase/server';
import { formatDate, formatPrice } from '@/lib/format';
import type { Product } from '@/lib/types';

export const dynamic = 'force-dynamic';

async function count(table: string, filter?: (q: any) => any) {
  const supabase = createClient();
  let q = supabase.from(table).select('*', { count: 'exact', head: true });
  if (filter) q = filter(q);
  const { count: c } = await q;
  return c ?? 0;
}

function StatCard({ label, value, accent }: { label: string; value: number; accent: string }) {
  return (
    <div className="card p-5">
      <div className="text-sm font-medium text-gray-500">{label}</div>
      <div className="mt-2 text-3xl font-extrabold" style={{ color: accent }}>
        {value}
      </div>
    </div>
  );
}

export default async function DashboardPage() {
  const supabase = createClient();

  const [totalProducts, activeProducts, inactiveProducts, featuredProducts, totalCategories] =
    await Promise.all([
      count('products'),
      count('products', (q) => q.eq('is_active', true)),
      count('products', (q) => q.eq('is_active', false)),
      count('products', (q) => q.eq('is_featured', true)),
      count('categories'),
    ]);

  const { data: recent } = await supabase
    .from('products')
    .select('id, name, price, sale_price, currency, is_active, updated_at, category:categories(name)')
    .order('updated_at', { ascending: false })
    .limit(6);

  const recentProducts = (recent ?? []) as unknown as Product[];

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-5">
        <StatCard label="Total Products" value={totalProducts} accent="#5E9C2C" />
        <StatCard label="Active" value={activeProducts} accent="#2E7D32" />
        <StatCard label="Inactive" value={inactiveProducts} accent="#9CA3AF" />
        <StatCard label="Featured" value={featuredProducts} accent="#F36B21" />
        <StatCard label="Categories" value={totalCategories} accent="#1976D2" />
      </div>

      <div className="flex flex-wrap gap-3">
        <Link href="/admin/products?new=1" className="btn-primary">
          + Add Product
        </Link>
        <Link href="/admin/categories" className="btn-secondary">
          Manage Categories
        </Link>
      </div>

      <div className="card">
        <div className="border-b border-gray-200 px-5 py-3 text-sm font-bold text-gray-900">
          Recently Updated Products
        </div>
        {recentProducts.length === 0 ? (
          <div className="p-8 text-center text-sm text-gray-500">
            No products yet. Click “Add Product” to create your first one.
          </div>
        ) : (
          <ul className="divide-y divide-gray-100">
            {recentProducts.map((p) => (
              <li key={p.id} className="flex items-center justify-between px-5 py-3">
                <div>
                  <div className="text-sm font-semibold text-gray-900">{p.name}</div>
                  <div className="text-xs text-gray-500">
                    {p.category?.name ?? 'Uncategorized'} · {formatDate(p.updated_at)}
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-sm font-semibold text-brand-greenDark">
                    {formatPrice(p.sale_price ?? p.price, p.currency)}
                  </span>
                  <span
                    className={`badge ${p.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}
                  >
                    {p.is_active ? 'Active' : 'Inactive'}
                  </span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
