'use client';

import { useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useToast } from './Toast';
import { ImageUploader } from './ImageUploader';
import { slugify } from '@/lib/format';
import { CURRENCIES, STOCK_LABELS, type Category, type Product, type StockStatus } from '@/lib/types';

interface Props {
  product: Product | null;
  categories: Category[];
  onClose: () => void;
  onSaved: () => void;
}

export function ProductForm({ product, categories, onClose, onSaved }: Props) {
  const { show } = useToast();
  const editing = !!product;

  const [name, setName] = useState(product?.name ?? '');
  const [description, setDescription] = useState(product?.description ?? '');
  const [shortDescription, setShortDescription] = useState(product?.short_description ?? '');
  const [categoryId, setCategoryId] = useState(product?.category_id ?? categories[0]?.id ?? '');
  const [sku, setSku] = useState(product?.sku ?? '');
  const [price, setPrice] = useState(product ? String(product.price) : '');
  const [salePrice, setSalePrice] = useState(product?.sale_price != null ? String(product.sale_price) : '');
  const [currency, setCurrency] = useState(product?.currency ?? 'SAR');
  const [imageUrl, setImageUrl] = useState(product?.image_url ?? '');
  const [additional, setAdditional] = useState<string[]>(product?.additional_images ?? []);
  const [stockStatus, setStockStatus] = useState<StockStatus>(product?.stock_status ?? 'in_stock');
  const [isFeatured, setIsFeatured] = useState(product?.is_featured ?? false);
  const [isActive, setIsActive] = useState(product?.is_active ?? true);
  const [isVeg, setIsVeg] = useState(product?.is_veg ?? true);
  const [sortOrder, setSortOrder] = useState(product ? String(product.sort_order) : '0');
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  function validate(): boolean {
    const e: Record<string, string> = {};
    if (!name.trim()) e.name = 'Product name is required.';
    if (!categoryId) e.category = 'Category is required.';
    const p = Number(price);
    if (price === '' || Number.isNaN(p)) e.price = 'A valid price is required.';
    else if (p < 0) e.price = 'Price cannot be negative.';
    if (salePrice !== '') {
      const sp = Number(salePrice);
      if (Number.isNaN(sp)) e.salePrice = 'Sale price must be a number.';
      else if (sp < 0) e.salePrice = 'Sale price cannot be negative.';
      else if (!Number.isNaN(p) && sp > p) e.salePrice = 'Sale price cannot be greater than the price.';
    }
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  async function onSubmit(ev: React.FormEvent) {
    ev.preventDefault();
    if (!validate()) return;
    setSaving(true);
    const supabase = createClient();

    const payload = {
      category_id: categoryId,
      name: name.trim(),
      description: description.trim(),
      short_description: shortDescription.trim(),
      sku: sku.trim() || null,
      price: Number(price),
      sale_price: salePrice === '' ? null : Number(salePrice),
      currency,
      image_url: imageUrl,
      additional_images: additional,
      stock_status: stockStatus,
      is_featured: isFeatured,
      is_active: isActive,
      is_veg: isVeg,
      sort_order: Number(sortOrder) || 0,
    };

    try {
      if (editing) {
        const { error } = await supabase.from('products').update(payload).eq('id', product!.id);
        if (error) throw error;
      } else {
        let slug = slugify(name);
        let attempt = 0;
        // Retry on unique-slug collision.
        while (attempt < 4) {
          const { error } = await supabase.from('products').insert({ ...payload, slug });
          if (!error) break;
          if (error.code === '23505') {
            slug = `${slugify(name)}-${Math.random().toString(36).slice(2, 6)}`;
            attempt++;
            continue;
          }
          throw error;
        }
      }
      show(editing ? 'Product updated.' : 'Product created.', 'success');
      onSaved();
    } catch (e: any) {
      show(e?.message ?? 'Save failed.', 'error');
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-black/40 p-4">
      <form onSubmit={onSubmit} className="card my-6 w-full max-w-3xl p-6">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-xl font-bold text-gray-900">{editing ? 'Edit Product' : 'Add Product'}</h2>
          <button type="button" onClick={onClose} className="text-gray-400 hover:text-gray-600">
            ✕
          </button>
        </div>

        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          <div className="md:col-span-2">
            <label className="label">Product name *</label>
            <input className="input" value={name} onChange={(e) => setName(e.target.value)} />
            {errors.name && <p className="mt-1 text-xs text-red-600">{errors.name}</p>}
          </div>

          <div>
            <label className="label">Category *</label>
            <select className="input" value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
              <option value="">Select a category…</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
            {errors.category && <p className="mt-1 text-xs text-red-600">{errors.category}</p>}
          </div>

          <div>
            <label className="label">SKU</label>
            <input className="input" value={sku} onChange={(e) => setSku(e.target.value)} />
          </div>

          <div>
            <label className="label">Price *</label>
            <input
              className="input"
              type="number"
              step="0.01"
              min="0"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
            />
            {errors.price && <p className="mt-1 text-xs text-red-600">{errors.price}</p>}
          </div>

          <div>
            <label className="label">Sale price</label>
            <input
              className="input"
              type="number"
              step="0.01"
              min="0"
              value={salePrice}
              onChange={(e) => setSalePrice(e.target.value)}
              placeholder="optional"
            />
            {errors.salePrice && <p className="mt-1 text-xs text-red-600">{errors.salePrice}</p>}
          </div>

          <div>
            <label className="label">Currency</label>
            <select className="input" value={currency} onChange={(e) => setCurrency(e.target.value)}>
              {CURRENCIES.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="label">Stock status</label>
            <select
              className="input"
              value={stockStatus}
              onChange={(e) => setStockStatus(e.target.value as StockStatus)}
            >
              {(Object.keys(STOCK_LABELS) as StockStatus[]).map((s) => (
                <option key={s} value={s}>
                  {STOCK_LABELS[s]}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="label">Sort order</label>
            <input
              className="input"
              type="number"
              value={sortOrder}
              onChange={(e) => setSortOrder(e.target.value)}
            />
          </div>

          <div className="md:col-span-2">
            <label className="label">Short description</label>
            <input
              className="input"
              value={shortDescription}
              onChange={(e) => setShortDescription(e.target.value)}
            />
          </div>

          <div className="md:col-span-2">
            <label className="label">Description</label>
            <textarea
              className="input min-h-[90px]"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          </div>

          <div className="md:col-span-2">
            <ImageUploader value={imageUrl} onChange={setImageUrl} label="Main product image" />
          </div>

          <div className="md:col-span-2">
            <span className="label">Additional images</span>
            <div className="flex flex-wrap gap-3">
              {additional.map((url, i) => (
                <div key={i} className="relative h-20 w-20 overflow-hidden rounded-lg border">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={url} alt="" className="h-full w-full object-cover" />
                  <button
                    type="button"
                    className="absolute right-0 top-0 bg-black/60 px-1 text-xs text-white"
                    onClick={() => setAdditional((a) => a.filter((_, j) => j !== i))}
                  >
                    ✕
                  </button>
                </div>
              ))}
              <div className="w-full max-w-xs">
                <ImageUploader
                  value=""
                  onChange={(url) => url && setAdditional((a) => [...a, url])}
                  label=""
                />
              </div>
            </div>
          </div>

          <div className="flex flex-wrap gap-6 md:col-span-2">
            <label className="flex items-center gap-2 text-sm font-medium text-gray-700">
              <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} />
              Active
            </label>
            <label className="flex items-center gap-2 text-sm font-medium text-gray-700">
              <input type="checkbox" checked={isFeatured} onChange={(e) => setIsFeatured(e.target.checked)} />
              Featured
            </label>
            <label className="flex items-center gap-2 text-sm font-medium text-gray-700">
              <input type="checkbox" checked={isVeg} onChange={(e) => setIsVeg(e.target.checked)} />
              Vegetarian
            </label>
          </div>
        </div>

        <div className="mt-6 flex justify-end gap-3">
          <button type="button" className="btn-secondary" onClick={onClose} disabled={saving}>
            Cancel
          </button>
          <button type="submit" className="btn-primary" disabled={saving}>
            {saving ? 'Saving…' : editing ? 'Save changes' : 'Create product'}
          </button>
        </div>
      </form>
    </div>
  );
}
