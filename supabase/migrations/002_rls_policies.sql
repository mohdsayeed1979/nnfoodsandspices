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
