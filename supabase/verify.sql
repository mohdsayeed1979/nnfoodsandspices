-- ============================================================================
-- NN Foods & Spices — verify.sql
-- Run in Supabase → SQL Editor AFTER applying the migrations. Each query
-- returns a labelled result so you can confirm the setup at a glance.
-- ============================================================================

-- 1) Tables exist -------------------------------------------------------------
select 'tables' as check, string_agg(table_name, ', ' order by table_name) as found
from information_schema.tables
where table_schema = 'public' and table_name in ('profiles', 'categories', 'products');
-- expect: categories, products, profiles

-- 2) RLS enabled on all three -------------------------------------------------
select 'rls_enabled' as check, relname as table, relrowsecurity as rls_on
from pg_class
where relname in ('profiles', 'categories', 'products')
order by relname;
-- expect rls_on = true for all three

-- 3) Policy counts ------------------------------------------------------------
select 'policies' as check, tablename, count(*) as policy_count
from pg_policies
where schemaname = 'public' and tablename in ('profiles', 'categories', 'products')
group by tablename
order by tablename;
-- expect: categories 4, products 4, profiles 2 (approx)

-- 4) is_admin() function exists ----------------------------------------------
select 'is_admin_fn' as check, count(*) as found
from pg_proc where proname = 'is_admin';
-- expect: 1

-- 5) Storage bucket -----------------------------------------------------------
select 'storage_bucket' as check, id, public, file_size_limit
from storage.buckets where id = 'product-images';
-- expect one row, public = true

-- 6) Storage policies ---------------------------------------------------------
select 'storage_policies' as check, count(*) as policy_count
from pg_policies
where schemaname = 'storage' and tablename = 'objects'
  and policyname like 'product_images_%';
-- expect: 4

-- 7) Indexes on products ------------------------------------------------------
select 'product_indexes' as check, string_agg(indexname, ', ' order by indexname) as indexes
from pg_indexes where schemaname = 'public' and tablename = 'products';

-- 8) Seeded category count ----------------------------------------------------
select 'category_count' as check, count(*) as categories from public.categories;
-- expect: 4

-- 9) Seeded product count -----------------------------------------------------
select 'product_count' as check, count(*) as products from public.products;
-- expect: 48

-- 10) Product count per category ---------------------------------------------
select 'per_category' as check, c.slug, count(p.id) as products
from public.categories c
left join public.products p on p.category_id = c.id
group by c.slug
order by c.slug;
-- expect: veg-spices 10, pure-spices 19, non-veg-spices 17, other-spices 2

-- 11) Sample product to confirm price mapping --------------------------------
select 'sample' as check, slug, price, sale_price, currency, is_active, is_featured
from public.products where slug = 'veg-spices-chole-masala';
-- expect: price 114, sale_price 95, currency INR, is_active true, is_featured true
