'use client';

import { useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useToast } from './Toast';
import { ImageUploader } from './ImageUploader';
import { slugify } from '@/lib/format';
import {
  CURRENCIES,
  PACK_MULTIPLIERS,
  STOCK_LABELS,
  type Category,
  type PackPrice,
  type Product,
  type StockStatus,
} from '@/lib/types';

/** Normalizes a product's raw pack_sizes (new {size,price} objects OR legacy
 * plain strings) into an editable price ladder, filling missing prices from
 * the base selling price via the standard multipliers. */
function normalizePacks(raw: Product['pack_sizes'] | undefined, base: number): PackPrice[] {
  const out: PackPrice[] = [];
  if (Array.isArray(raw)) {
    for (const e of raw) {
      if (typeof e === 'string') {
        if (e) out.push({ size: e, price: Math.round(base * (PACK_MULTIPLIERS[e] ?? 1)), active: true });
      } else if (e && typeof e === 'object' && e.size) {
        out.push({
          size: e.size,
          price: Number.isFinite(e.price) ? e.price : Math.round(base * (PACK_MULTIPLIERS[e.size] ?? 1)),
          active: e.active !== false,
        });
      }
    }
  }
  if (out.length === 0) {
    // A brand-new product starts with the common four; the admin can add,
    // remove or rename any of them (e.g. 2kg, 5kg) before saving.
    for (const [size, mult] of Object.entries(PACK_MULTIPLIERS)) {
      out.push({ size, price: Math.round(base * mult), active: true });
    }
  }
  return out;
}

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
  const [packs, setPacks] = useState<PackPrice[]>(() =>
    normalizePacks(product?.pack_sizes, product ? (product.sale_price ?? product.price) : 0),
  );
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
      // Persist variants as [{size, price, active}] — the single source of
      // truth read by the storefront and the Flutter app. Blank rows dropped.
      pack_sizes: packs
        .filter((p) => p.size.trim() !== '')
        .map((p) => ({ size: p.size.trim(), price: Number(p.price) || 0, active: p.active !== false })),
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
            <div className="mb-1 flex flex-wrap items-center justify-between gap-2">
              <span className="label">Pack sizes &amp; prices ({currency})</span>
              <button
                type="button"
                className="text-xs font-semibold text-brand-green hover:underline"
                onClick={() => {
                  const base = Number(salePrice) || Number(price) || 0;
                  setPacks((prev) =>
                    prev.map((p) =>
                      PACK_MULTIPLIERS[p.size]
                        ? { ...p, price: Math.round(base * PACK_MULTIPLIERS[p.size]) }
                        : p,
                    ),
                  );
                }}
                title="Recalculate the standard sizes (100g/250g/500g/1kg) from the current price"
              >
                Auto-fill standard sizes from base price
              </button>
            </div>

            <div className="space-y-2">
              <div className="hidden grid-cols-[1fr_1fr_auto_auto] gap-2 px-1 text-xs font-semibold text-gray-500 sm:grid">
                <span>Pack size</span>
                <span>Price</span>
                <span className="text-center">Active</span>
                <span></span>
              </div>
              {packs.map((p, i) => (
                <div key={i} className="grid grid-cols-[1fr_1fr_auto_auto] items-center gap-2">
                  <input
                    className="input"
                    placeholder="e.g. 250g / 2kg"
                    value={p.size}
                    onChange={(e) =>
                      setPacks((prev) => prev.map((x, j) => (j === i ? { ...x, size: e.target.value } : x)))
                    }
                  />
                  <input
                    className="input"
                    type="number"
                    step="0.01"
                    min="0"
                    value={p.price}
                    onChange={(e) =>
                      setPacks((prev) => prev.map((x, j) => (j === i ? { ...x, price: Number(e.target.value) } : x)))
                    }
                  />
                  <input
                    type="checkbox"
                    className="mx-auto h-5 w-5"
                    checked={p.active !== false}
                    title="Active — shown to customers"
                    onChange={(e) =>
                      setPacks((prev) => prev.map((x, j) => (j === i ? { ...x, active: e.target.checked } : x)))
                    }
                  />
                  <button
                    type="button"
                    className="px-2 text-lg text-red-500 hover:text-red-700"
                    title="Remove this variant"
                    onClick={() => setPacks((prev) => prev.filter((_, j) => j !== i))}
                  >
                    ✕
                  </button>
                </div>
              ))}
            </div>

            <button
              type="button"
              className="btn-secondary mt-2 text-sm"
              onClick={() => setPacks((prev) => [...prev, { size: '', price: 0, active: true }])}
            >
              + Add variant
            </button>
            <p className="mt-1 text-xs text-gray-400">
              Each product can have its own sizes — add only the packs this product is sold in (e.g. just
              100g &amp; 250g, or 1kg / 2kg / 5kg). The 100g price should match the product price above.
              These per-size prices are what customers see on the website and mobile app.
            </p>
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
