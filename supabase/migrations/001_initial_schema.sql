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
