# NN Foods & Spices — Admin Web Panel

A production Next.js (App Router) + TypeScript + Tailwind admin panel that
manages the same product catalog the mobile app displays. Auth, data, and
image storage are all real Supabase — no mocks, no localStorage database.

```
Flutter app ─┐
             ├─► Supabase (Postgres + Auth + Storage)  ◄─── Admin Web Panel (this)
   reads ────┘        RLS-enforced                              writes (admin only)
```

## Tech

- **Next.js 14** (App Router) · **TypeScript** · **Tailwind CSS**
- **@supabase/ssr** for cookie-based auth (middleware session refresh)
- Three layers of access control:
  1. **Middleware** — unauthenticated `/admin/*` → `/admin/login`
  2. **Server layout** — signed-in but non-admin → bounced to login
  3. **Postgres RLS** — the database itself rejects non-admin writes

## 1. Prerequisites

- Node 18+ and npm
- The Supabase project set up per [`../supabase/README.md`](../supabase/README.md)
  (migrations 001–004 applied)

## 2. Environment variables

Copy the example and fill in real values (never commit `.env.local`):

```bash
cp .env.example .env.local
```

| Variable | Scope | Purpose |
|----------|-------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | public | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | public | anon / publishable key (client-safe) |
| `SUPABASE_SERVICE_ROLE_KEY` | **server-only** | used **only** by the bootstrap script; NEVER in Vercel `NEXT_PUBLIC_*`, NEVER committed |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` / `ADMIN_FULL_NAME` | bootstrap-only | the initial admin to create |

Get the keys from Supabase → **Project Settings → API**.

## 3. Install & create the first admin

```bash
npm install
npm run bootstrap-admin      # reads .env.local; creates naqir59@gmail.com as admin
```

The bootstrap script (`scripts/bootstrap-admin.mjs`):
- creates the Supabase **Auth** user (or reuses it if it already exists — no duplicates, no password reset),
- upserts its `profiles` row with `role = 'admin'`, `is_active = true`.

The service-role key and password live only in your local `.env.local` and are
never sent to the browser or committed.

## 4. Run locally

```bash
npm run dev
# → http://localhost:3000/admin/login
```

Sign in with the admin email + password. You should land on the dashboard.

## 5. Build / lint (CI-style checks)

```bash
npm run lint
npm run build
```

## 6. Deploy to Vercel

1. Push this repo to GitHub (already done — see the main README).
2. In Vercel → **New Project** → import `mohdsayeed1979/nnfoodsandspices`.
3. Set **Root Directory** = `admin-web`.
4. Framework preset: **Next.js** (auto-detected). Build command `npm run build`.
5. **Environment Variables** (Production + Preview):
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - *(do NOT add the service-role key — the panel doesn't need it)*
6. Deploy. Note the production URL, e.g. `https://nnfoodsandspices-admin.vercel.app`.

### Supabase Auth redirect URLs

Supabase → **Authentication → URL Configuration**:
- **Site URL**: your Vercel production URL
- **Redirect URLs**: add `https://<your-vercel-domain>/auth/callback`
  (needed for the password-reset flow)

## 7. Using the panel

- **Dashboard** — totals (products, active, inactive, featured, categories) + recently updated + quick actions.
- **Products** — searchable/filterable/sortable table with pagination.
  - **Add / Edit** — name, category, SKU, price, sale price, currency, images, stock status, featured, active, veg, sort order. Validated (name/category/price required; sale ≤ price; non-negative).
  - **Activate / Deactivate** — soft hide (mobile app only shows active products).
  - **Feature / Unfeature** — controls the app's "Featured Products" row.
  - **Delete** — permanent, with a confirmation dialog; also removes the product's uploaded images from Storage.
- **Categories** — add/edit/reorder/activate/delete. Delete is blocked while any product still uses the category.
- **Images** — uploaded to the `product-images` Storage bucket (JPG/PNG/WebP, ≤ 5 MB, auto-downscaled to ≤ 1200 px). Public read; admin-only write.

### How changes reach the mobile app

Every change writes straight to Supabase. The Flutter app reads the live
catalog (active products/categories, prices, images, featured/stock status) on
launch, on pull-to-refresh, and when returning to listings — **no new Play
Store release is needed** for catalog changes. See the Flutter integration
section in the main README.

## 8. Creating another admin (safely)

Two options:
- **Re-run the bootstrap** with a different `ADMIN_EMAIL`/`ADMIN_PASSWORD` in `.env.local`, **or**
- In Supabase → **Authentication** create the user, then in **SQL Editor**:
  ```sql
  update public.profiles set role = 'admin', is_active = true
  where email = 'new-admin@example.com';
  ```

Never store admin passwords in code, SQL files, or the repo.
