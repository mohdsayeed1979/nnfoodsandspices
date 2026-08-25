export type StockStatus = 'in_stock' | 'out_of_stock' | 'coming_soon';
export type Role = 'admin' | 'viewer';

/** One pack size + its customer-facing selling price, stored in the
 * `products.pack_sizes` jsonb. Rows may still hold legacy plain strings,
 * so the raw column type is a union the admin form normalizes on load.
 * `active` (default true) lets an admin hide a variant without deleting it;
 * the storefront and the app only show active variants. */
export interface PackPrice {
  size: string;
  price: number;
  active?: boolean;
}
export type PackSizeEntry = string | PackPrice;

/** Standard pack multipliers off the 100g base — used only to pre-fill the
 * editor when a product has no explicit per-size prices yet. Matches the
 * Flutter app and storefront ladders. */
export const PACK_MULTIPLIERS: Record<string, number> = {
  '100g': 1.0,
  '250g': 2.3,
  '500g': 4.4,
  '1kg': 8.0,
};

export interface Category {
  id: string;
  slug: string;
  name: string;
  description: string;
  image_url: string;
  sort_order: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Product {
  id: string;
  category_id: string | null;
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
  pack_sizes: PackSizeEntry[];
  is_veg: boolean;
  is_active: boolean;
  is_featured: boolean;
  stock_status: StockStatus;
  rating: number;
  review_count: number;
  sort_order: number;
  created_at: string;
  updated_at: string;
  // Joined for display.
  category?: Pick<Category, 'id' | 'name' | 'slug'> | null;
}

export interface Profile {
  id: string;
  email: string;
  full_name: string | null;
  role: Role;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export const STOCK_LABELS: Record<StockStatus, string> = {
  in_stock: 'In Stock',
  out_of_stock: 'Out of Stock',
  coming_soon: 'Coming Soon',
};

export const CURRENCIES = ['SAR', 'INR', 'USD', 'AED'] as const;
