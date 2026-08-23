'use client';

import { useCallback, useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useToast } from './Toast';
import { ConfirmDialog } from './ConfirmDialog';
import { ImageUploader } from './ImageUploader';
import { formatDate, slugify } from '@/lib/format';
import type { Category } from '@/lib/types';

interface Draft {
  id?: string;
  name: string;
  description: string;
  image_url: string;
  sort_order: number;
  is_active: boolean;
}

const emptyDraft = (): Draft => ({
  name: '',
  description: '',
  image_url: '',
  sort_order: 0,
  is_active: true,
});

export function CategoriesClient() {
  const { show } = useToast();
  const [rows, setRows] = useState<(Category & { product_count: number })[]>([]);
  const [loading, setLoading] = useState(true);
  const [draft, setDraft] = useState<Draft | null>(null);
  const [saving, setSaving] = useState(false);
  const [nameError, setNameError] = useState('');
  const [deleteTarget, setDeleteTarget] = useState<Category | null>(null);
  const [deleting, setDeleting] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    const supabase = createClient();
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .order('sort_order', { ascending: true });
    if (error) {
      show(error.message, 'error');
      setLoading(false);
      return;
    }
    const cats = (data ?? []) as Category[];
    // Attach product counts (one lightweight count query per category).
    const withCounts = await Promise.all(
      cats.map(async (c) => {
        const { count } = await supabase
          .from('products')
          .select('*', { count: 'exact', head: true })
          .eq('category_id', c.id);
        return { ...c, product_count: count ?? 0 };
      }),
    );
    setRows(withCounts);
    setLoading(false);
  }, [show]);

  useEffect(() => {
    load();
  }, [load]);

  async function save() {
    if (!draft) return;
    if (!draft.name.trim()) {
      setNameError('Category name is required.');
      return;
    }
    setNameError('');
    setSaving(true);
    const supabase = createClient();
    const payload = {
      name: draft.name.trim(),
      description: draft.description.trim(),
      image_url: draft.image_url,
      sort_order: Number(draft.sort_order) || 0,
      is_active: draft.is_active,
    };
    try {
      if (draft.id) {
        const { error } = await supabase.from('categories').update(payload).eq('id', draft.id);
        if (error) throw error;
      } else {
        let slug = slugify(draft.name);
        let attempt = 0;
        while (attempt < 4) {
          const { error } = await supabase.from('categories').insert({ ...payload, slug });
          if (!error) break;
          if (error.code === '23505') {
            slug = `${slugify(draft.name)}-${Math.random().toString(36).slice(2, 5)}`;
            attempt++;
            continue;
          }
          throw error;
        }
      }
      show(draft.id ? 'Category updated.' : 'Category created.', 'success');
      setDraft(null);
      load();
    } catch (e: any) {
      show(e?.message ?? 'Save failed.', 'error');
    } finally {
      setSaving(false);
    }
  }

  async function toggleActive(c: Category) {
    const supabase = createClient();
    const { error } = await supabase
      .from('categories')
      .update({ is_active: !c.is_active })
      .eq('id', c.id);
    if (error) return show(error.message, 'error');
    show(c.is_active ? 'Deactivated.' : 'Activated.', 'success');
    load();
  }

  async function reorder(c: Category, dir: -1 | 1) {
    const supabase = createClient();
    const { error } = await supabase
      .from('categories')
      .update({ sort_order: c.sort_order + dir })
      .eq('id', c.id);
    if (error) return show(error.message, 'error');
    load();
  }

  async function doDelete(c: Category) {
    setDeleting(true);
    const supabase = createClient();
    const { count } = await supabase
      .from('products')
      .select('*', { count: 'exact', head: true })
      .eq('category_id', c.id);
    if ((count ?? 0) > 0) {
      setDeleting(false);
      setDeleteTarget(null);
      show(`Cannot delete “${c.name}” — ${count} product(s) still use it. Reassign or delete them first.`, 'error');
      return;
    }
    const { error } = await supabase.from('categories').delete().eq('id', c.id);
    setDeleting(false);
    setDeleteTarget(null);
    if (error) return show(error.message, 'error');
    show('Category deleted.', 'success');
    load();
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <button className="btn-primary" onClick={() => setDraft(emptyDraft())}>
          + Add Category
        </button>
      </div>

      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[720px] text-sm">
            <thead className="border-b border-gray-200 bg-gray-50 text-left text-xs uppercase tracking-wide text-gray-500">
              <tr>
                <th className="px-4 py-3">Order</th>
                <th className="px-4 py-3">Category</th>
                <th className="px-4 py-3">Products</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Updated</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-4 py-10 text-center text-gray-400">
                    Loading…
                  </td>
                </tr>
              ) : rows.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-10 text-center text-gray-400">
                    No categories yet.
                  </td>
                </tr>
              ) : (
                rows.map((c) => (
                  <tr key={c.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1">
                        <span className="w-6 text-gray-500">{c.sort_order}</span>
                        <button className="rounded border px-1.5 text-xs" onClick={() => reorder(c, -1)}>
                          ↑
                        </button>
                        <button className="rounded border px-1.5 text-xs" onClick={() => reorder(c, 1)}>
                          ↓
                        </button>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="font-medium text-gray-900">{c.name}</div>
                      <div className="text-xs text-gray-400">{c.slug}</div>
                    </td>
                    <td className="px-4 py-3 text-gray-600">{c.product_count}</td>
                    <td className="px-4 py-3">
                      <span className={`badge ${c.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                        {c.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-gray-500">{formatDate(c.updated_at)}</td>
                    <td className="px-4 py-3">
                      <div className="flex justify-end gap-1.5 text-xs">
                        <button
                          className="rounded border border-gray-300 px-2 py-1 hover:bg-gray-100"
                          onClick={() =>
                            setDraft({
                              id: c.id,
                              name: c.name,
                              description: c.description,
                              image_url: c.image_url,
                              sort_order: c.sort_order,
                              is_active: c.is_active,
                            })
                          }
                        >
                          Edit
                        </button>
                        <button
                          className="rounded border border-gray-300 px-2 py-1 hover:bg-gray-100"
                          onClick={() => toggleActive(c)}
                        >
                          {c.is_active ? 'Deactivate' : 'Activate'}
                        </button>
                        <button
                          className="rounded border border-red-300 px-2 py-1 text-red-600 hover:bg-red-50"
                          onClick={() => setDeleteTarget(c)}
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
      </div>

      {/* Add / edit modal */}
      {draft && (
        <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-black/40 p-4">
          <div className="card my-6 w-full max-w-lg p-6">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-xl font-bold text-gray-900">
                {draft.id ? 'Edit Category' : 'Add Category'}
              </h2>
              <button onClick={() => setDraft(null)} className="text-gray-400 hover:text-gray-600">
                ✕
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="label">Name *</label>
                <input
                  className="input"
                  value={draft.name}
                  onChange={(e) => setDraft({ ...draft, name: e.target.value })}
                />
                {nameError && <p className="mt-1 text-xs text-red-600">{nameError}</p>}
              </div>
              <div>
                <label className="label">Description</label>
                <textarea
                  className="input min-h-[70px]"
                  value={draft.description}
                  onChange={(e) => setDraft({ ...draft, description: e.target.value })}
                />
              </div>
              <div>
                <label className="label">Sort order</label>
                <input
                  className="input"
                  type="number"
                  value={draft.sort_order}
                  onChange={(e) => setDraft({ ...draft, sort_order: Number(e.target.value) })}
                />
              </div>
              <ImageUploader
                value={draft.image_url}
                onChange={(url) => setDraft({ ...draft, image_url: url })}
                label="Category image"
              />
              <label className="flex items-center gap-2 text-sm font-medium text-gray-700">
                <input
                  type="checkbox"
                  checked={draft.is_active}
                  onChange={(e) => setDraft({ ...draft, is_active: e.target.checked })}
                />
                Active
              </label>
            </div>
            <div className="mt-6 flex justify-end gap-3">
              <button className="btn-secondary" onClick={() => setDraft(null)} disabled={saving}>
                Cancel
              </button>
              <button className="btn-primary" onClick={save} disabled={saving}>
                {saving ? 'Saving…' : draft.id ? 'Save changes' : 'Create category'}
              </button>
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete category?"
        message={`Delete “${deleteTarget?.name}”? This is only allowed if no products use it.`}
        confirmLabel="Delete"
        danger
        busy={deleting}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && doDelete(deleteTarget)}
      />
    </div>
  );
}
