-- ============================================================================
-- NN Foods & Spices — apply_all.sql  (CONVENIENCE: 001+002+003+004 combined)
-- Generated from the individual migrations — do NOT edit here; edit the
-- numbered files in migrations/ and re-run tools/concat if needed.
-- Paste this whole file into Supabase → SQL Editor → New query → Run.
-- Idempotent: safe to re-run.
-- ============================================================================


-- ===== migrations/001_initial_schema.sql =====

-- ============================================================================
-- NN Foods & Spices — 001_initial_schema.sql
-- Core tables: profiles (admin roles), categories, products.
-- Run this first in the Supabase SQL editor (or via `supabase db push`).
-- ============================================================================

create extension if not exists "uuid-ossp";

-- ----------------------------------------------------------------------------
-- updated_at helper trigger
-- ----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- profiles — one row per auth user, holds the admin role.
-- Never stores passwords (Supabase Auth owns credentials in auth.users).
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text unique not null,
  full_name   text,
  role        text not null default 'viewer' check (role in ('admin', 'viewer')),
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Auto-create a profile row whenever a new auth user is created.
-- New users default to role 'viewer' + inactive so they get NO admin access
-- until an existing admin (or the bootstrap script) promotes them.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role, is_active)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    'viewer',
    false
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ----------------------------------------------------------------------------
-- is_admin() — single source of truth for admin authorization, used by RLS.
-- SECURITY DEFINER so RLS policies can call it without recursive policy checks.
-- ----------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'admin'
      and p.is_active = true
  );
$$;

-- ----------------------------------------------------------------------------
-- categories
-- `slug` is the stable public identifier the mobile app uses as its
-- category id (preserves existing app behaviour); `id` is a clean UUID PK.
-- ----------------------------------------------------------------------------
create table if not exists public.categories (
  id          uuid primary key default uuid_generate_v4(),
  slug        text unique not null,
  name        text not null,
  description text not null default '',
  image_url   text not null default '',
  sort_order  integer not null default 0,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

drop trigger if exists trg_categories_updated on public.categories;
create trigger trg_categories_updated
  before update on public.categories
  for each row execute function public.set_updated_at();

create index if not exists idx_categories_active_sort
  on public.categories (is_active, sort_order);

-- ----------------------------------------------------------------------------
-- products
-- Prices use numeric(12,2) — never floating point.
-- `slug` = stable public id the mobile app uses as Product.id (preserves
-- existing Hive-stored cart/wishlist keys on users' devices).
-- ----------------------------------------------------------------------------
create table if not exists public.products (
  id                uuid primary key default uuid_generate_v4(),
  category_id       uuid references public.categories(id) on delete restrict,
  slug              text unique not null,
  name              text not null,
  description       text not null default '',
  short_description text not null default '',
  sku               text,
  price             numeric(12,2) not null default 0 check (price >= 0),
  sale_price        numeric(12,2) check (sale_price is null or sale_price >= 0),
  currency          text not null default 'SAR',
  image_url         text not null default '',
  additional_images jsonb not null default '[]'::jsonb,
  pack_sizes        jsonb not null default '["100g","250g","500g","1kg"]'::jsonb,
  is_veg            boolean not null default true,
  is_active         boolean not null default true,
  is_featured       boolean not null default false,
  stock_status      text not null default 'in_stock'
                      check (stock_status in ('in_stock', 'out_of_stock', 'coming_soon')),
  rating            numeric(2,1) not null default 4.5 check (rating >= 0 and rating <= 5),
  review_count      integer not null default 0 check (review_count >= 0),
  sort_order        integer not null default 0,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  -- Sale price cannot exceed the regular price.
  constraint sale_le_price check (sale_price is null or sale_price <= price)
);

drop trigger if exists trg_products_updated on public.products;
create trigger trg_products_updated
  before update on public.products
  for each row execute function public.set_updated_at();

create index if not exists idx_products_category   on public.products (category_id);
create index if not exists idx_products_active      on public.products (is_active);
create index if not exists idx_products_featured    on public.products (is_featured) where is_featured;
create index if not exists idx_products_active_sort on public.products (is_active, sort_order);
-- Case-insensitive search on name + sku.
create index if not exists idx_products_name_lower  on public.products (lower(name));
create index if not exists idx_products_sku_lower   on public.products (lower(sku));

-- ===== migrations/002_rls_policies.sql =====

-- ============================================================================
-- NN Foods & Spices — 002_rls_policies.sql
-- Row Level Security. Run AFTER 001_initial_schema.sql.
--
-- Enforcement summary (enforced by the DATABASE, not just the UI):
--   anon / mobile users : read active categories + active products only
--   authenticated non-admin : same read rights, NO write access
--   admin (profiles.role='admin' AND is_active) : full read + write
-- ============================================================================

alter table public.profiles   enable row level security;
alter table public.categories enable row level security;
alter table public.products   enable row level security;

-- ----------------------------------------------------------------------------
-- profiles
-- ----------------------------------------------------------------------------
drop policy if exists profiles_select_self_or_admin on public.profiles;
create policy profiles_select_self_or_admin
  on public.profiles for select
  using (id = auth.uid() or public.is_admin());

-- Only admins may change roles / activate / deactivate other profiles.
drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update
  on public.profiles for update
  using (public.is_admin())
  with check (public.is_admin());

-- Inserts happen via the SECURITY DEFINER handle_new_user() trigger only.
-- No direct INSERT policy is granted to clients.

-- ----------------------------------------------------------------------------
-- categories
-- ----------------------------------------------------------------------------
drop policy if exists categories_public_read on public.categories;
create policy categories_public_read
  on public.categories for select
  using (is_active = true or public.is_admin());

drop policy if exists categories_admin_insert on public.categories;
create policy categories_admin_insert
  on public.categories for insert
  with check (public.is_admin());

drop policy if exists categories_admin_update on public.categories;
create policy categories_admin_update
  on public.categories for update
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists categories_admin_delete on public.categories;
create policy categories_admin_delete
  on public.categories for delete
  using (public.is_admin());

-- ----------------------------------------------------------------------------
-- products
-- ----------------------------------------------------------------------------
drop policy if exists products_public_read on public.products;
create policy products_public_read
  on public.products for select
  using (is_active = true or public.is_admin());

drop policy if exists products_admin_insert on public.products;
create policy products_admin_insert
  on public.products for insert
  with check (public.is_admin());

drop policy if exists products_admin_update on public.products;
create policy products_admin_update
  on public.products for update
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists products_admin_delete on public.products;
create policy products_admin_delete
  on public.products for delete
  using (public.is_admin());

-- ===== migrations/003_storage_policies.sql =====

-- ============================================================================
-- NN Foods & Spices — 003_storage_policies.sql
-- Supabase Storage bucket for product / category images.
-- Run AFTER 002_rls_policies.sql.
--
--   public (anon + mobile users) : read images only
--   admin                        : upload / replace / delete images
-- ============================================================================

-- Create a public-read bucket (idempotent).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  true,
  5242880, -- 5 MB
  array['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Public read (the bucket is public, but we add an explicit SELECT policy too).
drop policy if exists product_images_public_read on storage.objects;
create policy product_images_public_read
  on storage.objects for select
  using (bucket_id = 'product-images');

-- Only admins may upload.
drop policy if exists product_images_admin_insert on storage.objects;
create policy product_images_admin_insert
  on storage.objects for insert
  with check (bucket_id = 'product-images' and public.is_admin());

-- Only admins may replace/update.
drop policy if exists product_images_admin_update on storage.objects;
create policy product_images_admin_update
  on storage.objects for update
  using (bucket_id = 'product-images' and public.is_admin())
  with check (bucket_id = 'product-images' and public.is_admin());

-- Only admins may delete.
drop policy if exists product_images_admin_delete on storage.objects;
create policy product_images_admin_delete
  on storage.objects for delete
  using (bucket_id = 'product-images' and public.is_admin());

-- ===== migrations/004_seed_catalog.sql =====

-- ============================================================================
-- NN Foods & Spices — 004_seed_catalog.sql  (GENERATED — do not edit by hand)
-- Regenerate with:  node supabase/generate_seed.mjs > supabase/migrations/004_seed_catalog.sql
--
-- The real published NN Food & Spices catalog: 4 categories, 48 products.
-- Seeded with currency 'INR' and empty image_url to preserve the exact
-- current appearance of the deployed mobile app (empty image_url renders the
-- app's branded placeholder tile). Idempotent via ON CONFLICT (slug).
-- ============================================================================

insert into public.categories (slug, name, description, sort_order, is_active)
values ('veg-spices', 'Veg Spices', '100% vegetarian spice blends formulated for a variety of dishes.', 1, true)
on conflict (slug) do update set
  name = excluded.name, description = excluded.description,
  sort_order = excluded.sort_order, is_active = excluded.is_active;

insert into public.categories (slug, name, description, sort_order, is_active)
values ('pure-spices', 'Pure Spices', 'Single-ingredient ground spices and dried herbs, naturally pure.', 2, true)
on conflict (slug) do update set
  name = excluded.name, description = excluded.description,
  sort_order = excluded.sort_order, is_active = excluded.is_active;

insert into public.categories (slug, name, description, sort_order, is_active)
values ('non-veg-spices', 'Non-Veg Spices', 'Signature masala blends crafted for chicken, mutton and fish.', 3, true)
on conflict (slug) do update set
  name = excluded.name, description = excluded.description,
  sort_order = excluded.sort_order, is_active = excluded.is_active;

insert into public.categories (slug, name, description, sort_order, is_active)
values ('other-spices', 'Other Spices', 'Street-food favourites and specialty blends.', 4, true)
on conflict (slug) do update set
  name = excluded.name, description = excluded.description,
  sort_order = excluded.sort_order, is_active = excluded.is_active;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-chole-masala', 'Chole Masala', 'Chole Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chole Masala', 'VEG-SPICES-CHOLE-MASALA',
  114, 95, 'INR',
  true, true, true, 'in_stock', 4.2, 8, 0
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-fried-rice-masala', 'Fried Rice Masala', 'Fried Rice Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Fried Rice Masala', 'VEG-SPICES-FRIED-RICE-MASALA',
  102, null, 'INR',
  true, true, false, 'in_stock', 4.3, 11, 1
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-kitchen-king-masala', 'Kitchen King Masala', 'Kitchen King Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Kitchen King Masala', 'VEG-SPICES-KITCHEN-KING-MASALA',
  109, null, 'INR',
  true, true, false, 'in_stock', 4.4, 14, 2
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-noodles-masala', 'Noodles Masala', 'Noodles Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Noodles Masala', 'VEG-SPICES-NOODLES-MASALA',
  116, null, 'INR',
  true, true, false, 'in_stock', 4.5, 17, 3
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-paneer-matar-masala', 'Paneer Matar Masala', 'Paneer Matar Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Paneer Matar Masala', 'VEG-SPICES-PANEER-MATAR-MASALA',
  148, 123, 'INR',
  true, true, false, 'in_stock', 4.6, 20, 4
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-paneer-tikka-masala', 'Paneer Tikka Masala', 'Paneer Tikka Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Paneer Tikka Masala', 'VEG-SPICES-PANEER-TIKKA-MASALA',
  130, null, 'INR',
  true, true, true, 'in_stock', 4.7, 23, 5
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-sabji-masala', 'Sabji Masala', 'Sabji Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Sabji Masala', 'VEG-SPICES-SABJI-MASALA',
  97, null, 'INR',
  true, true, false, 'in_stock', 4.2, 26, 6
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-sambhar-powder', 'Sambhar Powder', 'Sambhar Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Sambhar Powder', 'VEG-SPICES-SAMBHAR-POWDER',
  104, null, 'INR',
  true, true, false, 'in_stock', 4.3, 29, 7
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-shahi-malai-paneer-masala', 'Shahi Malai Paneer Masala', 'Shahi Malai Paneer Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Shahi Malai Paneer Masala', 'VEG-SPICES-SHAHI-MALAI-PANEER-MASALA',
  133, 111, 'INR',
  true, true, false, 'in_stock', 4.4, 32, 8
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-veg-manchuria-masala', 'Veg Manchuria Masala', 'Veg Manchuria Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Veg Manchuria Masala', 'VEG-SPICES-VEG-MANCHURIA-MASALA',
  118, null, 'INR',
  true, true, false, 'in_stock', 4.5, 35, 9
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-amchur-powder', 'Amchur Powder', 'Amchur Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Amchur Powder', 'PURE-SPICES-AMCHUR-POWDER',
  84, 70, 'INR',
  true, true, true, 'in_stock', 4.2, 8, 0
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-black-pepper-powder', 'Black Pepper Powder', 'Black Pepper Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Black Pepper Powder', 'PURE-SPICES-BLACK-PEPPER-POWDER',
  77, null, 'INR',
  true, true, false, 'in_stock', 4.3, 11, 1
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-coriander-leaf', 'Coriander Leaf', 'Coriander Leaf by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Coriander Leaf', 'PURE-SPICES-CORIANDER-LEAF',
  84, null, 'INR',
  true, true, false, 'in_stock', 4.4, 14, 2
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-curry-leaf', 'Curry Leaf', 'Curry Leaf by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Curry Leaf', 'PURE-SPICES-CURRY-LEAF',
  91, null, 'INR',
  true, true, false, 'in_stock', 4.5, 17, 3
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-garam-masala', 'Garam Masala', 'Garam Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Garam Masala', 'PURE-SPICES-GARAM-MASALA',
  118, 98, 'INR',
  true, true, false, 'in_stock', 4.6, 20, 4
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-garlic-powder', 'Garlic Powder', 'Garlic Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Garlic Powder', 'PURE-SPICES-GARLIC-POWDER',
  105, null, 'INR',
  true, true, true, 'in_stock', 4.7, 23, 5
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-ginger-powder', 'Ginger Powder', 'Ginger Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Ginger Powder', 'PURE-SPICES-GINGER-POWDER',
  72, null, 'INR',
  true, true, false, 'in_stock', 4.2, 26, 6
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-green-capsicum-flakes', 'Green Capsicum Flakes', 'Green Capsicum Flakes by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Green Capsicum Flakes', 'PURE-SPICES-GREEN-CAPSICUM-FLAKES',
  79, null, 'INR',
  true, true, false, 'in_stock', 4.3, 29, 7
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-green-chilli-flakes', 'Green Chilli Flakes', 'Green Chilli Flakes by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Green Chilli Flakes', 'PURE-SPICES-GREEN-CHILLI-FLAKES',
  103, 86, 'INR',
  true, true, false, 'in_stock', 4.4, 32, 8
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-imli-powder', 'Imli Powder', 'Imli Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Imli Powder', 'PURE-SPICES-IMLI-POWDER',
  93, null, 'INR',
  true, true, false, 'in_stock', 4.5, 35, 9
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-jeera-powder', 'Jeera Powder', 'Jeera Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Jeera Powder', 'PURE-SPICES-JEERA-POWDER',
  100, null, 'INR',
  true, true, true, 'in_stock', 4.6, 38, 10
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-kasuri-methi-leaves', 'Kasuri Methi Leaves', 'Kasuri Methi Leaves by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Kasuri Methi Leaves', 'PURE-SPICES-KASURI-METHI-LEAVES',
  107, null, 'INR',
  true, true, false, 'in_stock', 4.7, 41, 11
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-lemon-powder', 'Lemon Powder', 'Lemon Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Lemon Powder', 'PURE-SPICES-LEMON-POWDER',
  89, 74, 'INR',
  true, true, false, 'in_stock', 4.2, 44, 12
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-mint-leaf', 'Mint Leaf', 'Mint Leaf by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Mint Leaf', 'PURE-SPICES-MINT-LEAF',
  81, null, 'INR',
  true, true, false, 'in_stock', 4.3, 47, 13
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-moringa-leaf', 'Moringa Leaf', 'Moringa Leaf by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Moringa Leaf', 'PURE-SPICES-MORINGA-LEAF',
  88, null, 'INR',
  true, true, false, 'in_stock', 4.4, 50, 14
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-onion-powder', 'Onion Powder', 'Onion Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Onion Powder', 'PURE-SPICES-ONION-POWDER',
  95, null, 'INR',
  true, true, true, 'in_stock', 4.5, 53, 15
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-oregano-leaves', 'Oregano Leaves', 'Oregano Leaves by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Oregano Leaves', 'PURE-SPICES-OREGANO-LEAVES',
  122, 102, 'INR',
  true, true, false, 'in_stock', 4.6, 56, 16
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-paprika-powder', 'Paprika Powder', 'Paprika Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Paprika Powder', 'PURE-SPICES-PAPRIKA-POWDER',
  109, null, 'INR',
  true, true, false, 'in_stock', 4.7, 59, 17
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-parsley-leaves', 'Parsley Leaves', 'Parsley Leaves by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Parsley Leaves', 'PURE-SPICES-PARSLEY-LEAVES',
  76, null, 'INR',
  true, true, false, 'in_stock', 4.2, 62, 18
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-biryani-masala', 'Biryani Masala', 'Biryani Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Biryani Masala', 'NON-VEG-SPICES-BIRYANI-MASALA',
  132, 110, 'INR',
  false, true, true, 'in_stock', 4.2, 8, 0
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-chicken-65-masala', 'Chicken 65 Masala', 'Chicken 65 Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chicken 65 Masala', 'NON-VEG-SPICES-CHICKEN-65-MASALA',
  117, null, 'INR',
  false, true, false, 'in_stock', 4.3, 11, 1
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-chicken-biryani-masala', 'Chicken Biryani Masala', 'Chicken Biryani Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chicken Biryani Masala', 'NON-VEG-SPICES-CHICKEN-BIRYANI-MASALA',
  124, null, 'INR',
  false, true, false, 'in_stock', 4.4, 14, 2
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-chicken-khorma-masala', 'Chicken Khorma Masala', 'Chicken Khorma Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chicken Khorma Masala', 'NON-VEG-SPICES-CHICKEN-KHORMA-MASALA',
  131, null, 'INR',
  false, true, false, 'in_stock', 4.5, 17, 3
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-chicken-manchurian-masala', 'Chicken Manchurian Masala', 'Chicken Manchurian Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chicken Manchurian Masala', 'NON-VEG-SPICES-CHICKEN-MANCHURIAN-MASALA',
  166, 138, 'INR',
  false, true, false, 'in_stock', 4.6, 20, 4
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-chicken-masala', 'Chicken Masala', 'Chicken Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chicken Masala', 'NON-VEG-SPICES-CHICKEN-MASALA',
  145, null, 'INR',
  false, true, true, 'in_stock', 4.7, 23, 5
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-chicken-tikka-masala', 'Chicken Tikka Masala', 'Chicken Tikka Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chicken Tikka Masala', 'NON-VEG-SPICES-CHICKEN-TIKKA-MASALA',
  112, null, 'INR',
  false, true, false, 'in_stock', 4.2, 26, 6
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-fish-masala', 'Fish Masala', 'Fish Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Fish Masala', 'NON-VEG-SPICES-FISH-MASALA',
  119, null, 'INR',
  false, true, false, 'in_stock', 4.3, 29, 7
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-karahi-ghost-masala', 'Karahi Ghost Masala', 'Karahi Ghost Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Karahi Ghost Masala', 'NON-VEG-SPICES-KARAHI-GHOST-MASALA',
  151, 126, 'INR',
  false, true, false, 'in_stock', 4.4, 32, 8
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-mutton-bbq-masala', 'Mutton BBQ Masala', 'Mutton BBQ Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Mutton BBQ Masala', 'NON-VEG-SPICES-MUTTON-BBQ-MASALA',
  133, null, 'INR',
  false, true, false, 'in_stock', 4.5, 35, 9
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-mutton-khorma-masala', 'Mutton Khorma Masala', 'Mutton Khorma Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Mutton Khorma Masala', 'NON-VEG-SPICES-MUTTON-KHORMA-MASALA',
  140, null, 'INR',
  false, true, true, 'in_stock', 4.6, 38, 10
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-mutton-masala', 'Mutton Masala', 'Mutton Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Mutton Masala', 'NON-VEG-SPICES-MUTTON-MASALA',
  147, null, 'INR',
  false, true, false, 'in_stock', 4.7, 41, 11
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-nihari-potli-masala', 'Nihari Potli Masala', 'Nihari Potli Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Nihari Potli Masala', 'NON-VEG-SPICES-NIHARI-POTLI-MASALA',
  137, 114, 'INR',
  false, true, false, 'in_stock', 4.2, 44, 12
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-shahi-malai-chicken-masala', 'Shahi Malai Chicken Masala', 'Shahi Malai Chicken Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Shahi Malai Chicken Masala', 'NON-VEG-SPICES-SHAHI-MALAI-CHICKEN-MASALA',
  121, null, 'INR',
  false, true, false, 'in_stock', 4.3, 47, 13
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-shahi-malai-mutton-masala', 'Shahi Malai Mutton Masala', 'Shahi Malai Mutton Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Shahi Malai Mutton Masala', 'NON-VEG-SPICES-SHAHI-MALAI-MUTTON-MASALA',
  128, null, 'INR',
  false, true, false, 'in_stock', 4.4, 50, 14
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-tandoori-masala-and-bbq', 'Tandoori Masala and BBQ', 'Tandoori Masala and BBQ by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Tandoori Masala and BBQ', 'NON-VEG-SPICES-TANDOORI-MASALA-AND-BBQ',
  135, null, 'INR',
  false, true, true, 'in_stock', 4.5, 53, 15
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-chapli-kabab-masala', 'Chapli Kabab Masala', 'Chapli Kabab Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chapli Kabab Masala', 'NON-VEG-SPICES-CHAPLI-KABAB-MASALA',
  170, 142, 'INR',
  false, true, false, 'in_stock', 4.6, 56, 16
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'other-spices'),
  'other-spices-pani-puri-masala', 'Pani Puri Masala', 'Pani Puri Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Pani Puri Masala', 'OTHER-SPICES-PANI-PURI-MASALA',
  108, 90, 'INR',
  true, true, true, 'in_stock', 4.2, 8, 0
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'other-spices'),
  'other-spices-pav-bhaji-masala', 'Pav Bhaji Masala', 'Pav Bhaji Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Pav Bhaji Masala', 'OTHER-SPICES-PAV-BHAJI-MASALA',
  97, null, 'INR',
  true, true, false, 'in_stock', 4.3, 11, 1
)
on conflict (slug) do nothing;

