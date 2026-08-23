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
