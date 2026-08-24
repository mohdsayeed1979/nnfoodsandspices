import { createClient, type SupabaseClient } from '@supabase/supabase-js';

/**
 * Public, read-only Supabase client using the anon/publishable key.
 * Row Level Security restricts anonymous access to active products and
 * active categories only — the anon key grants nothing beyond that.
 *
 * Returns null when env vars are absent so the app builds and renders a
 * graceful empty state instead of crashing (real data flows once
 * NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY are set).
 *
 * `global.fetch` forces every request through this client to skip Next.js's
 * Data Cache. Route segment config (`dynamic = 'force-dynamic'`) only
 * reliably disables that cache on routes that also read a request-time API
 * (searchParams, cookies, headers) — a route with none of those, like the
 * home page, can still get a stale cached response from a library fetch()
 * even with force-dynamic set. Setting `cache: 'no-store'` here makes every
 * catalog read bypass the cache unconditionally, regardless of the route.
 */
let cached: SupabaseClient | null | undefined;

function noStoreFetch(input: RequestInfo | URL, init?: RequestInit) {
  return fetch(input, { ...init, cache: 'no-store' });
}

export function getSupabase(): SupabaseClient | null {
  if (cached !== undefined) return cached;
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  cached = url && anon
    ? createClient(url, anon, { auth: { persistSession: false }, global: { fetch: noStoreFetch } })
    : null;
  return cached;
}
