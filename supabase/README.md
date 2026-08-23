# Supabase Backend — NN Foods & Spices

This folder holds the database schema, security policies, storage policies, and
seed data for the live product catalog. Everything here is idempotent and
version-controlled — no undocumented manual changes.

## Project

| | |
|---|---|
| Project URL | `https://ajpwcpmedyhqqoycxokb.supabase.co` |
| Project ref | `ajpwcpmedyhqqoycxokb` |

## Migration order

Run these **in order** in the Supabase Dashboard → **SQL Editor** (or via the
Supabase CLI — see below). Each file is safe to re-run.

| # | File | What it does |
|---|------|--------------|
| 001 | `migrations/001_initial_schema.sql` | `profiles`, `categories`, `products` tables + `is_admin()` + triggers |
| 002 | `migrations/002_rls_policies.sql` | Row Level Security: public reads active rows; only admins write |
| 003 | `migrations/003_storage_policies.sql` | `product-images` bucket (public read, admin write) |
| 004 | `migrations/004_seed_catalog.sql` | The real 48-product / 4-category catalog (generated) |

Then create the admin **auth** user with the bootstrap script — see
`admin-web/README.md` (it needs the service-role key and cannot be a plain SQL
migration).

### Option A — SQL Editor (simplest, no install)

1. Open the project → **SQL Editor** → **New query**.
2. Paste the whole of **`apply_all.sql`** (all four migrations, unchanged and
   concatenated for one-paste convenience) → **Run**.
   *(Or paste `001_…`, `002_…`, `003_…`, `004_…` one at a time in order.)*
3. New query → paste **`verify.sql`** → **Run** to confirm the setup
   (tables, RLS on, policy counts, bucket, indexes, **4 categories / 48
   products**, per-category counts, and a sample price-mapping row).

### Option B — Supabase CLI

```bash
npm install -g supabase
supabase link --project-ref ajpwcpmedyhqqoycxokb
# Applies every file in migrations/ in order:
supabase db push
```

## Data model

### `products`
- `id` UUID PK · `slug` (stable public id used by the mobile app) · `category_id` FK
- `name`, `description`, `short_description`, `sku`
- `price` `numeric(12,2)` (regular) · `sale_price` `numeric(12,2)` (≤ price) · `currency` (default `SAR`)
- `image_url`, `additional_images` (jsonb) · `pack_sizes` (jsonb) · `is_veg`
- `is_active`, `is_featured`, `stock_status` (`in_stock` / `out_of_stock` / `coming_soon`)
- `rating`, `review_count`, `sort_order`, `created_at`, `updated_at`

> **Price mapping:** the mobile app shows `sale_price` as the selling price and
> `price` struck through. So a product on offer has `price` = original,
> `sale_price` = discounted. The seed reproduces the deployed app exactly.

### `categories`
- `id` UUID PK · `slug` (used as the app's category id) · `name`, `description`, `image_url`
- `sort_order`, `is_active`, timestamps

### `profiles`
- `id` = `auth.users.id` · `email`, `full_name`
- `role` (`admin` / `viewer`) · `is_active` · timestamps
- New signups default to `viewer` + inactive (no admin access until promoted).

## Security (RLS) — enforced by the database, not just the UI

| Table | anon / mobile | authenticated non-admin | admin |
|-------|---------------|-------------------------|-------|
| `categories` | read active | read active | full CRUD |
| `products` | read active | read active | full CRUD |
| `profiles` | — | read own row | read all + manage roles |
| storage `product-images` | read | read | upload / replace / delete |

`is_admin()` = `profiles.role = 'admin' AND is_active = true`, evaluated with
`auth.uid()`. The service-role key bypasses RLS and is used **only** by the
server-side bootstrap script — never in the browser or the Flutter app.

## Regenerating the seed

```bash
node supabase/generate_seed.mjs   # rewrites migrations/004_seed_catalog.sql
```
