'use client';

import { useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { useToast } from './Toast';
import { ProductForm } from './ProductForm';
import { ConfirmDialog } from './ConfirmDialog';
import { formatDate, formatPrice } from '@/lib/format';
import { STOCK_LABELS, type Category, type Product } from '@/lib/types';

const PAGE_SIZE = 20;

export function ProductsClient({ categories }: { categories: Category[] }) {
  const { show } = useToast();
  const params = useSearchParams();

  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(0);

  const [search, setSearch] = useState('');
  const [debounced, setDebounced] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');
  const [sort, setSort] = useState<'updated' | 'name' | 'price'>('updated');

  const [editing, setEditing] = useState<Product | null>(null);
  const [showForm, setShowForm] = useState(params.get('new') === '1');
  const [deleteTarget, setDeleteTarget] = useState<Product | null>(null);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    const t = setTimeout(() => setDebounced(search), 350);
    return () => clearTimeout(t);
  }, [search]);

  const load = useCallback(async () => {
    setLoading(true);
    const supabase = createClient();
    let q = supabase
      .from('products')
      .select('*, category:categories(id, name, slug)', { count: 'exact' });

    if (debounced.trim()) {
      const term = debounced.trim();
      q = q.or(`name.ilike.%${term}%,sku.ilike.%${term}%`);
    }
    if (categoryFilter) q = q.eq('category_id', categoryFilter);
    if (statusFilter === 'active') q = q.eq('is_active', true);
    if (statusFilter === 'inactive') q = q.eq('is_active', false);

    if (sort === 'name') q = q.order('name', { ascending: true });
    else if (sort === 'price') q = q.order('price', { ascending: true });
    else q = q.order('updated_at', { ascending: false });

    q = q.range(page * PAGE_SIZE, page * PAGE_SIZE + PAGE_SIZE - 1);

    const { data, error, count } = await q;
    if (error) {
      show(error.message, 'error');
      setProducts([]);
    } else {
      setProducts((data ?? []) as unknown as Product[]);
      setTotal(count ?? 0);
    }
    setLoading(false);
  }, [debounced, categoryFilter, statusFilter, sort, page, show]);

  useEffect(() => {
    load();
  }, [load]);

  // Reset to first page when filters change.
  useEffect(() => {
    setPage(0);
  }, [debounced, categoryFilter, statusFilter, sort]);

  async function patch(p: Product, changes: Partial<Product>, msg: string) {
    const supabase = createClient();
    const { error } = await supabase.from('products').update(changes).eq('id', p.id);
    if (error) {
      show(error.message, 'error');
      return;
    }
    show(msg, 'success');
    load();
  }

  async function permanentDelete(p: Product) {
    setDeleting(true);
    const supabase = createClient();
    // Clean up storage objects owned by our bucket (best-effort).
    const urls = [p.image_url, ...(p.additional_images ?? [])].filter((u) =>
      u.includes('/product-images/'),
    );
    const paths = urls.map((u) => u.split('/product-images/')[1]).filter(Boolean);
    if (paths.length) {
      try {
        await supabase.storage.from('product-images').remove(paths);
      } catch {
        /* ignore orphan cleanup failures */
      }
    }
    const { error } = await supabase.from('products').delete().eq('id', p.id);
    setDeleting(false);
    setDeleteTarget(null);
    if (error) {
      show(error.message, 'error');
      return;
    }
    show('Product permanently deleted.', 'success');
    load();
  }

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="space-y-4">
      {/* Toolbar */}
      <div className="card p-4">
        <div className="flex flex-wrap items-end gap-3">
          <div className="min-w-[200px] flex-1">
            <label className="label">Search (name or SKU)</label>
            <input
              className="input"
              placeholder="Search products…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          <div>
            <label className="label">Category</label>
            <select className="input" value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)}>
              <option value="">All</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="label">Status</label>
            <select className="input" value={statusFilter} onChange={(e) => setStatusFilter(e.target.value as any)}>
              <option value="all">All</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>
          <div>
            <label className="label">Sort</label>
            <select className="input" value={sort} onChange={(e) => setSort(e.target.value as any)}>
              <option value="updated">Recently updated</option>
              <option value="name">Name (A–Z)</option>
              <option value="price">Price (low–high)</option>
            </select>
          </div>
          <button className="btn-secondary" onClick={() => load()} disabled={loading}>
            ↻ Refresh
          </button>
          <button
            className="btn-primary"
            onClick={() => {
              setEditing(null);
              setShowForm(true);
            }}
          >
            + Add Product
          </button>
        </div>
      </div>

      {/* Table */}
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[860px] text-sm">
            <thead className="border-b border-gray-200 bg-gray-50 text-left text-xs uppercase tracking-wide text-gray-500">
              <tr>
                <th className="px-4 py-3">Product</th>
                <th className="px-4 py-3">Category</th>
                <th className="px-4 py-3">SKU</th>
                <th className="px-4 py-3">Price</th>
                <th className="px-4 py-3">Sale</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Featured</th>
                <th className="px-4 py-3">Stock</th>
                <th className="px-4 py-3">Updated</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {loading ? (
                <tr>
                  <td colSpan={10} className="px-4 py-10 text-center text-gray-400">
                    Loading…
                  </td>
                </tr>
              ) : products.length === 0 ? (
                <tr>
                  <td colSpan={10} className="px-4 py-10 text-center text-gray-400">
                    No products found.
                  </td>
                </tr>
              ) : (
                products.map((p) => (
                  <tr key={p.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="h-10 w-10 shrink-0 overflow-hidden rounded-md bg-gray-100">
                          {p.image_url ? (
                            // eslint-disable-next-line @next/next/no-img-element
                            <img src={p.image_url} alt="" className="h-full w-full object-cover" />
                          ) : (
                            <div className="flex h-full w-full items-center justify-center text-[10px] text-gray-400">
                              N/A
                            </div>
                          )}
                        </div>
                        <span className="font-medium text-gray-900">{p.name}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-gray-600">{p.category?.name ?? '—'}</td>
                    <td className="px-4 py-3 text-gray-500">{p.sku ?? '—'}</td>
                    <td className="px-4 py-3 font-medium">{formatPrice(p.price, p.currency)}</td>
                    <td className="px-4 py-3">{p.sale_price != null ? formatPrice(p.sale_price, p.currency) : '—'}</td>
                    <td className="px-4 py-3">
                      <span className={`badge ${p.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                        {p.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="px-4 py-3">{p.is_featured ? '⭐' : '—'}</td>
                    <td className="px-4 py-3 text-gray-600">{STOCK_LABELS[p.stock_status]}</td>
                    <td className="px-4 py-3 text-gray-500">{formatDate(p.updated_at)}</td>
                    <td className="px-4 py-3">
                      <div className="flex justify-end gap-1.5 whitespace-nowrap text-xs">
                        <button
                          className="rounded border border-gray-300 px-2 py-1 hover:bg-gray-100"
                          onClick={() => {
                            setEditing(p);
                            setShowForm(true);
                          }}
                        >
                          Edit
                        </button>
                        <button
                          className="rounded border border-gray-300 px-2 py-1 hover:bg-gray-100"
                          onClick={() =>
                            patch(p, { is_active: !p.is_active }, p.is_active ? 'Deactivated.' : 'Activated.')
                          }
                        >
                          {p.is_active ? 'Deactivate' : 'Activate'}
                        </button>
                        <button
                          className="rounded border border-gray-300 px-2 py-1 hover:bg-gray-100"
                          onClick={() =>
                            patch(p, { is_featured: !p.is_featured }, p.is_featured ? 'Unfeatured.' : 'Featured.')
                          }
                        >
                          {p.is_featured ? 'Unfeature' : 'Feature'}
                        </button>
                        <button
                          className="rounded border border-red-300 px-2 py-1 text-red-600 hover:bg-red-50"
                          onClick={() => setDeleteTarget(p)}
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="flex items-center justify-between border-t border-gray-200 px-4 py-3 text-sm text-gray-600">
          <span>
            {total} product{total === 1 ? '' : 's'} · page {page + 1} of {totalPages}
          </span>
          <div className="flex gap-2">
            <button
              className="btn-secondary"
              disabled={page === 0}
              onClick={() => setPage((p) => Math.max(0, p - 1))}
            >
              Previous
            </button>
            <button
              className="btn-secondary"
              disabled={page + 1 >= totalPages}
              onClick={() => setPage((p) => p + 1)}
            >
              Next
            </button>
          </div>
        </div>
      </div>

      {showForm && (
        <ProductForm
          product={editing}
          categories={categories}
          onClose={() => setShowForm(false)}
          onSaved={() => {
            setShowForm(false);
            load();
          }}
        />
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete product?"
        message={`Are you sure you want to permanently delete “${deleteTarget?.name}”? This also removes its uploaded images and cannot be undone. To hide it instead, use Deactivate.`}
        confirmLabel="Delete permanently"
        danger
        busy={deleting}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && permanentDelete(deleteTarget)}
      />
    </div>
  );
}
