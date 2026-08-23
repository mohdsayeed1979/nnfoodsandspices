import { createClient, type SupabaseClient } from '@supabase/supabase-js';

/**
 * Public, read-only Supabase client using the anon/publishable key.
 * Row Level Security restricts anonymous access to active products and
 * active categories only — the anon key grants nothing beyond that.
 *
 * Returns null when env vars are absent so the app builds and renders a
 * graceful empty state instead of crashing (real data flows once
 * NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY are set).
 */
let cached: SupabaseClient | null | undefined;

export function getSupabase(): SupabaseClient | null {
  if (cached !== undefined) return cached;
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  cached = url && anon ? createClient(url, anon, { auth: { persistSession: false } }) : null;
  return cached;
}
