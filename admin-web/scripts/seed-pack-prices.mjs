// ============================================================================
// seed-pack-prices.mjs — one-time migration that fills each product's
// `pack_sizes` jsonb with per-size selling prices [{size, price}], derived
// from the product's 100g base selling price (sale_price ?? price) using the
// standard pack multipliers. After this runs, `pack_sizes` is the single
// source of truth the storefront + Flutter app read for per-size pricing;
// admins edit the numbers from the panel afterwards.
//
// SAFE BY DEFAULT: no args = DRY RUN (prints what it would change, writes a
// backup + report, touches nothing). Pass --apply (with the service-role key)
// to actually write. The service key bypasses RLS, so keep it in a LOCAL,
// gitignored .env.local — never commit or paste it.
//
// Usage (from admin-web/):
//   npm run seed-pack-prices            # dry run
//   npm run seed-pack-prices -- --apply # write (needs SUPABASE_SERVICE_ROLE_KEY)
//
// Idempotent: re-running recomputes from the current base price. It only
// rewrites rows whose pack_sizes differ from the computed ladder.
// ============================================================================

import { readFileSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { createClient } from '@supabase/supabase-js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const OUT_DIR = join(__dirname, 'output');

const APPLY = process.argv.includes('--apply');

const MULTIPLIERS = { '100g': 1.0, '250g': 2.3, '500g': 4.4, '1kg': 8.0 };

function loadEnvLocal() {
  const p = join(ROOT, '.env.local');
  if (!existsSync(p)) return;
  for (const line of readFileSync(p, 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
}
loadEnvLocal();

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://ajpwcpmedyhqqoycxokb.supabase.co';
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (APPLY && !SERVICE_KEY) {
  console.error('\n--apply requires SUPABASE_SERVICE_ROLE_KEY (Project Settings -> API -> service_role).\n');
  process.exit(1);
}

const readClient = createClient(SUPABASE_URL, SERVICE_KEY || ANON_KEY, { auth: { persistSession: false } });
const writeClient = APPLY ? createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } }) : null;

/** The size labels a product currently declares, in order. Accepts the new
 * object shape or legacy plain strings; falls back to the standard four. */
function currentSizes(packSizes) {
  const labels = [];
  if (Array.isArray(packSizes)) {
    for (const e of packSizes) {
      if (typeof e === 'string' && e) labels.push(e);
      else if (e && typeof e === 'object' && e.size) labels.push(String(e.size));
    }
  }
  return labels.length ? labels : Object.keys(MULTIPLIERS);
}

function ladderFor(base, sizes) {
  return sizes.map((size) => ({ size, price: Math.round(base * (MULTIPLIERS[size] ?? 1)) }));
}

async function main() {
  mkdirSync(OUT_DIR, { recursive: true });

  console.log(`Mode: ${APPLY ? 'APPLY (will write to Supabase)' : 'DRY RUN (no writes)'}`);
  const { data: products, error } = await readClient
    .from('products')
    .select('id, slug, name, price, sale_price, pack_sizes')
    .order('name', { ascending: true });
  if (error) throw new Error(`Failed to read products: ${error.message}`);
  console.log(`Found ${products.length} products.\n`);

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupPath = join(OUT_DIR, `pack_sizes_backup_before_seed_${timestamp}.json`);
  writeFileSync(
    backupPath,
    JSON.stringify(
      products.map((p) => ({ id: p.id, slug: p.slug, name: p.name, price: p.price, sale_price: p.sale_price, pack_sizes: p.pack_sizes })),
      null,
      2,
    ),
  );
  console.log(`Backup written: ${backupPath}\n`);

  const report = [];
  let changed = 0, unchanged = 0, failed = 0;

  for (const p of products) {
    const base = p.sale_price != null ? Number(p.sale_price) : Number(p.price);
    const sizes = currentSizes(p.pack_sizes);
    const ladder = ladderFor(base, sizes);
    const before = JSON.stringify(p.pack_sizes);
    const after = JSON.stringify(ladder);
    const row = { name: p.name, slug: p.slug, base, ladder, action: 'PENDING' };

    if (before === after) {
      row.action = 'UNCHANGED';
      unchanged++;
      report.push(row);
      continue;
    }

    if (!APPLY) {
      row.action = 'WOULD UPDATE';
      changed++;
      report.push(row);
      console.log(`[dry] ${p.name}: base ${base} -> ${ladder.map((l) => `${l.size}:${l.price}`).join('  ')}`);
      continue;
    }

    const { error: upErr } = await writeClient.from('products').update({ pack_sizes: ladder }).eq('id', p.id);
    if (upErr) {
      row.action = 'FAILED';
      row.error = upErr.message;
      failed++;
      console.error(`${p.name}: FAILED — ${upErr.message}`);
    } else {
      row.action = 'UPDATED';
      changed++;
      console.log(`${p.name}: UPDATED -> ${ladder.map((l) => `${l.size}:${l.price}`).join('  ')}`);
    }
    report.push(row);
  }

  const reportPath = join(OUT_DIR, `pack_sizes_seed_report_${timestamp}.json`);
  writeFileSync(reportPath, JSON.stringify(report, null, 2));

  console.log('\n=== Summary ===');
  console.table({ changed, unchanged, failed });
  console.log(`Report: ${reportPath}`);
  if (!APPLY) console.log('\nDRY RUN — nothing written. Re-run with --apply to persist.');
}

main().catch((e) => {
  console.error('\nFatal error:', e);
  process.exit(1);
});
