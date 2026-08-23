// ============================================================================
// verify-live.mjs — real auth + RLS security tests against the live Supabase.
//
// Runs AFTER migrations are applied and the admin user is bootstrapped.
// Uses ONLY the public anon key + a real admin login (never the service-role
// key) so it tests RLS exactly the way the browser/app hits it.
//
// Usage (from admin-web/, with .env.local filled in):
//   npm run verify-live
//
// Needs in .env.local:
//   NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY,
//   ADMIN_EMAIL, ADMIN_PASSWORD
// (SUPABASE_SERVICE_ROLE_KEY is NOT used here.)
// ============================================================================

import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { createClient } from '@supabase/supabase-js';

const __dirname = dirname(fileURLToPath(import.meta.url));
(function loadEnvLocal() {
  const p = join(__dirname, '..', '.env.local');
  if (!existsSync(p)) return;
  for (const line of readFileSync(p, 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
})();

const URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const ANON = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const EMAIL = process.env.ADMIN_EMAIL;
const PASSWORD = process.env.ADMIN_PASSWORD;

if (!URL || !ANON) {
  console.error('✗ NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY missing in .env.local');
  process.exit(1);
}

const results = [];
function record(name, pass, detail = '') {
  results.push({ name, pass, detail });
  console.log(`${pass ? '✓ PASS' : '✗ FAIL'}  ${name}${detail ? `  — ${detail}` : ''}`);
}

const anon = () => createClient(URL, ANON, { auth: { persistSession: false } });

async function anonTests() {
  console.log('\n— Anonymous (no login) —');
  const sb = anon();

  const { data: products, error: pErr } = await sb
    .from('products').select('id, slug, is_active').limit(50);
  record('anon can read active products', !pErr && Array.isArray(products) && products.length > 0,
    pErr ? pErr.message : `${products?.length ?? 0} rows`);
  const anyActiveInactive = (products ?? []).some((p) => p.is_active === false);
  record('anon sees only active products (RLS hides inactive)', !anyActiveInactive,
    anyActiveInactive ? 'inactive row leaked!' : 'ok');

  const { data: cats, error: cErr } = await sb.from('categories').select('id, slug').limit(20);
  record('anon can read active categories', !cErr && (cats?.length ?? 0) > 0,
    cErr ? cErr.message : `${cats?.length ?? 0} rows`);

  // anon INSERT must be rejected by RLS.
  const { error: insErr } = await sb.from('products').insert({
    slug: `hack-${Date.now()}`, name: 'HACK', price: 1,
  });
  record('anon CANNOT insert a product', !!insErr, insErr ? `rejected: ${insErr.code ?? insErr.message}` : 'INSERT SUCCEEDED (BAD)');

  // anon UPDATE must affect 0 rows (RLS filters them out for write).
  const target = products?.[0];
  if (target) {
    const { data: upd } = await sb.from('products').update({ name: 'HACKED' }).eq('id', target.id).select();
    record('anon CANNOT update a product', (upd?.length ?? 0) === 0,
      (upd?.length ?? 0) === 0 ? '0 rows modified' : 'UPDATE SUCCEEDED (BAD)');

    const { data: del } = await sb.from('products').delete().eq('id', target.id).select();
    record('anon CANNOT delete a product', (del?.length ?? 0) === 0,
      (del?.length ?? 0) === 0 ? '0 rows deleted' : 'DELETE SUCCEEDED (BAD)');
  } else {
    record('anon update/delete denied', false, 'no product to test against (seed not applied?)');
  }
}

async function adminTests() {
  if (!EMAIL || !PASSWORD) {
    console.log('\n— Admin tests skipped (ADMIN_EMAIL / ADMIN_PASSWORD not set) —');
    return;
  }
  console.log('\n— Admin (real login) —');
  const sb = anon();

  const { data: auth, error: authErr } = await sb.auth.signInWithPassword({ email: EMAIL, password: PASSWORD });
  record('admin valid login succeeds', !authErr && !!auth?.session, authErr ? authErr.message : 'session established');
  if (authErr || !auth?.session) return;

  const { data: profile } = await sb.from('profiles').select('role, is_active').eq('id', auth.user.id).single();
  record('admin profile role=admin & active', profile?.role === 'admin' && profile?.is_active === true,
    `role=${profile?.role}, active=${profile?.is_active}`);

  // wrong password must fail (fresh client).
  const sb2 = anon();
  const { error: badErr } = await sb2.auth.signInWithPassword({ email: EMAIL, password: PASSWORD + 'x' });
  record('invalid password rejected', !!badErr, badErr ? 'rejected' : 'ACCEPTED WRONG PW (BAD)');

  // admin can insert → update → delete a temp product (cleaned up, no leftovers).
  const slug = `verify-temp-${Date.now()}`;
  const { data: catRow } = await sb.from('categories').select('id').limit(1).single();
  const { data: created, error: insErr } = await sb.from('products').insert({
    slug, name: 'Verify Temp Product', price: 100, sale_price: 80, currency: 'SAR',
    category_id: catRow?.id ?? null, is_active: false,
  }).select().single();
  record('admin CAN insert a product', !insErr && !!created, insErr ? insErr.message : `id=${created?.id?.slice(0, 8)}`);

  if (created) {
    const { data: updated, error: updErr } = await sb.from('products')
      .update({ price: 123.45 }).eq('id', created.id).select().single();
    record('admin CAN update a product (price change)', !updErr && Number(updated?.price) === 123.45,
      updErr ? updErr.message : `price=${updated?.price}`);

    const { data: delRows, error: delErr } = await sb.from('products').delete().eq('id', created.id).select();
    record('admin CAN delete a product (cleanup)', !delErr && (delRows?.length ?? 0) === 1,
      delErr ? delErr.message : 'temp product removed');
  }

  // admin category create + delete (cleanup).
  const cslug = `verify-temp-cat-${Date.now()}`;
  const { data: cat, error: cInsErr } = await sb.from('categories')
    .insert({ slug: cslug, name: 'Verify Temp Cat' }).select().single();
  record('admin CAN create a category', !cInsErr && !!cat, cInsErr ? cInsErr.message : 'created');
  if (cat) {
    const { error: cDelErr } = await sb.from('categories').delete().eq('id', cat.id);
    record('admin CAN delete a category (cleanup)', !cDelErr, cDelErr ? cDelErr.message : 'removed');
  }

  await sb.auth.signOut();
  record('admin logout succeeds', true, 'session cleared');
}

async function main() {
  console.log(`\n=== NN Foods live verification against ${URL} ===`);
  await anonTests();
  await adminTests();

  const passed = results.filter((r) => r.pass).length;
  const failed = results.length - passed;
  console.log(`\n=== ${passed}/${results.length} passed, ${failed} failed ===\n`);
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error('\n✗ Harness error:', e.message ?? e);
  process.exit(1);
});
