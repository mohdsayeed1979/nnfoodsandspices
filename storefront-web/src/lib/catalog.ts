import { getSupabase } from './supabase';
import { packPricesFrom } from './format';
import type { Category, Product, SortKey } from './types';

const PRODUCT_SELECT = '*, category:categories(slug, name)';

function mapProduct(row: Record<string, any>): Product {
  const price = Number(row.price ?? 0);
  const salePrice = row.sale_price == null ? null : Number(row.sale_price);
  return {
    id: row.id,
    slug: row.slug,
    name: row.name ?? '',
    description: row.description ?? '',
    short_description: row.short_description ?? '',
    sku: row.sku ?? null,
    price,
    sale_price: salePrice,
    currency: row.currency ?? 'INR',
    image_url: row.image_url ?? '',
    additional_images: Array.isArray(row.additional_images) ? row.additional_images : [],
    pack_prices: packPricesFrom(row.pack_sizes, salePrice ?? price),
    is_featured: !!row.is_featured,
    is_veg: !!row.is_veg,
    stock_status: row.stock_status ?? 'in_stock',
    sort_order: Number(row.sort_order ?? 0),
    category: row.category
      ? { slug: row.category.slug, name: row.category.name }
      : null,
  };
}

/** Active categories (ordered), each with a live active-product count. */
export async function getCategories(): Promise<Category[]> {
  const sb = getSupabase();
  if (!sb) return [];
  try {
    const { data, error } = await sb
      .from('categories')
      .select('id, slug, name, description, image_url, sort_order')
      .eq('is_active', true)
      .order('sort_order', { ascending: true });
    if (error || !data) return [];

    return await Promise.all(
      data.map(async (c) => {
        const { count } = await sb
          .from('products')
          .select('*', { count: 'exact', head: true })
          .eq('category_id', c.id)
          .eq('is_active', true);
        return { ...c, product_count: count ?? 0 } as Category;
      }),
    );
  } catch {
    return [];
  }
}

export async function getCategoryBySlug(slug: string): Promise<Category | null> {
  const sb = getSupabase();
  if (!sb) return null;
  try {
    const { data } = await sb
      .from('categories')
      .select('id, slug, name, description, image_url, sort_order')
      .eq('slug', slug)
      .eq('is_active', true)
      .maybeSingle();
    return (data as Category) ?? null;
  } catch {
    return null;
  }
}

interface ProductQuery {
  search?: string;
  categorySlug?: string;
  featured?: boolean;
  sort?: SortKey;
  page?: number;
  pageSize?: number;
}

export async function getProducts(
  q: ProductQuery = {},
): Promise<{ products: Product[]; total: number }> {
  const sb = getSupabase();
  if (!sb) return { products: [], total: 0 };
  const page = Math.max(1, q.page ?? 1);
  const pageSize = q.pageSize ?? 12;
  try {
    let query = sb.from('products').select(PRODUCT_SELECT, { count: 'exact' }).eq('is_active', true);

    if (q.categorySlug) {
      const cat = await sb
        .from('categories')
        .select('id')
        .eq('slug', q.categorySlug)
        .maybeSingle();
      if (!cat.data) return { products: [], total: 0 };
      query = query.eq('category_id', cat.data.id);
    }
    if (q.search && q.search.trim()) {
      const term = q.search.trim();
      query = query.or(`name.ilike.%${term}%,sku.ilike.%${term}%`);
    }
    if (q.featured) query = query.eq('is_featured', true);

    switch (q.sort) {
      case 'price-asc':
        query = query.order('price', { ascending: true });
        break;
      case 'price-desc':
        query = query.order('price', { ascending: false });
        break;
      case 'name':
        query = query.order('name', { ascending: true });
        break;
      case 'newest':
        query = query.order('created_at', { ascending: false });
        break;
      case 'featured':
      default:
        query = query.order('is_featured', { ascending: false }).order('sort_order', { ascending: true });
        break;
    }

    const from = (page - 1) * pageSize;
    const { data, error, count } = await query.range(from, from + pageSize - 1);
    if (error || !data) return { products: [], total: 0 };
    return { products: data.map(mapProduct), total: count ?? 0 };
  } catch {
    return { products: [], total: 0 };
  }
}

export async function getFeaturedProducts(limit = 8): Promise<Product[]> {
  const sb = getSupabase();
  if (!sb) return [];
  try {
    const { data } = await sb
      .from('products')
      .select(PRODUCT_SELECT)
      .eq('is_active', true)
      .eq('is_featured', true)
      .order('sort_order', { ascending: true })
      .limit(limit);
    return (data ?? []).map(mapProduct);
  } catch {
    return [];
  }
}

export async function getPopularProducts(limit = 8): Promise<Product[]> {
  const sb = getSupabase();
  if (!sb) return [];
  try {
    const { data } = await sb
      .from('products')
      .select(PRODUCT_SELECT)
      .eq('is_active', true)
      .order('rating', { ascending: false })
      .limit(limit);
    return (data ?? []).map(mapProduct);
  } catch {
    return [];
  }
}

export async function getProductBySlug(slug: string): Promise<Product | null> {
  const sb = getSupabase();
  if (!sb) return null;
  try {
    const { data } = await sb
      .from('products')
      .select(PRODUCT_SELECT)
      .eq('slug', slug)
      .eq('is_active', true)
      .maybeSingle();
    return data ? mapProduct(data) : null;
  } catch {
    return null;
  }
}

export async function getRelatedProducts(
  categorySlug: string | undefined,
  excludeSlug: string,
  limit = 4,
): Promise<Product[]> {
  const sb = getSupabase();
  if (!sb || !categorySlug) return [];
  try {
    const cat = await sb.from('categories').select('id').eq('slug', categorySlug).maybeSingle();
    if (!cat.data) return [];
    const { data } = await sb
      .from('products')
      .select(PRODUCT_SELECT)
      .eq('is_active', true)
      .eq('category_id', cat.data.id)
      .neq('slug', excludeSlug)
      .limit(limit);
    return (data ?? []).map(mapProduct);
  } catch {
    return [];
  }
}

/** Slugs for sitemap.xml (active only). */
export async function getAllProductSlugs(): Promise<string[]> {
  const sb = getSupabase();
  if (!sb) return [];
  try {
    const { data } = await sb.from('products').select('slug').eq('is_active', true);
    return (data ?? []).map((r) => r.slug as string);
  } catch {
    return [];
  }
}

export async function getAllCategorySlugs(): Promise<string[]> {
  const sb = getSupabase();
  if (!sb) return [];
  try {
    const { data } = await sb.from('categories').select('slug').eq('is_active', true);
    return (data ?? []).map((r) => r.slug as string);
  } catch {
    return [];
  }
}
