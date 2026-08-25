export type StockStatus = 'in_stock' | 'out_of_stock' | 'coming_soon';

/** Customer-facing selling price for one pack size (mirrors the DB
 * `products.pack_sizes` jsonb — the single source of truth for per-size
 * prices, shared with the Flutter app). */
export interface PackPrice {
  size: string;
  price: number;
}

export interface Category {
  id: string;
  slug: string;
  name: string;
  description: string;
  image_url: string;
  sort_order: number;
  product_count?: number;
}

export interface Product {
  id: string;
  slug: string;
  name: string;
  description: string;
  short_description: string;
  sku: string | null;
  price: number;
  sale_price: number | null;
  currency: string;
  image_url: string;
  additional_images: string[];
  pack_prices: PackPrice[];
  is_featured: boolean;
  is_veg: boolean;
  stock_status: StockStatus;
  sort_order: number;
  category: { slug: string; name: string } | null;
}

export const STOCK_LABELS: Record<StockStatus, string> = {
  in_stock: 'In Stock',
  out_of_stock: 'Out of Stock',
  coming_soon: 'Coming Soon',
};

export type SortKey = 'featured' | 'newest' | 'price-asc' | 'price-desc' | 'name';
