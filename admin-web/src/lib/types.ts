export type StockStatus = 'in_stock' | 'out_of_stock' | 'coming_soon';
export type Role = 'admin' | 'viewer';

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
  pack_sizes: string[];
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
