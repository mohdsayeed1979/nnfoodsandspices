// ============================================================================
// bulk-import-images.mjs — imports the 48 product photos from the official
// NN Foods & Spices WordPress site (nnfoodsandspices.com) into the Supabase
// catalog that the admin panel, storefront-web and the Flutter app all read.
//
// SAFE BY DEFAULT: running this script with no flags only DOWNLOADS,
// VALIDATES and PROCESSES images to scripts/output/ and writes a matching
// report — it never touches Supabase. Nothing is uploaded or written to the
// database unless you pass --apply.
//
// SECURITY: --apply needs the Supabase SERVICE-ROLE key (bypasses RLS, so it
// can write like an admin). Read it from env or a LOCAL, gitignored
// .env.local — NEVER commit it, NEVER paste it in chat.
//
// Usage (from admin-web/):
//   1) Dry run — download, process, produce the report only:
//        npm run import-images
//   2) Review scripts/output/matching-report.json and the processed .webp
//      files in scripts/output/processed/ — check they look right.
//   3) Apply — upload to Storage + update the DB (writes a backup first):
//        cp .env.example .env.local   (fill in SUPABASE_SERVICE_ROLE_KEY)
//        npm run import-images -- --apply
//
// Idempotent-ish: safe to re-run. Each run's backup/report is timestamped so
// nothing gets overwritten; a failed run can be resumed by pointing back at
// the same backup file to see which slugs never got an UPDATE.
// ============================================================================

import { readFileSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { createClient } from '@supabase/supabase-js';
import sharp from 'sharp';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const OUT_DIR = join(__dirname, 'output');
const PROCESSED_DIR = join(OUT_DIR, 'processed');

const APPLY = process.argv.includes('--apply');
const REQUEST_DELAY_MS = 400; // be polite to the source WordPress site
const MAX_LONG_EDGE = 1600;
const WEBP_QUALITY = 82;
const BUCKET = 'product-images';

// ---------------------------------------------------------------------------
// env
// ---------------------------------------------------------------------------
function loadEnvLocal() {
  const p = join(ROOT, '.env.local');
  if (!existsSync(p)) return;
  for (const line of readFileSync(p, 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m && !process.env[m[1]]) {
      process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
    }
  }
}
loadEnvLocal();

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://ajpwcpmedyhqqoycxokb.supabase.co';
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (APPLY && !SERVICE_KEY) {
  console.error(
    '\n--apply requires SUPABASE_SERVICE_ROLE_KEY (Project Settings -> API -> service_role).\n' +
      'Set it in admin-web/.env.local (gitignored) or as an env var, then re-run with --apply.\n',
  );
  process.exit(1);
}

// Reads use the service key when available (so --apply runs see the very
// latest data), otherwise fall back to the anon key for a pure dry run.
const readClient = createClient(SUPABASE_URL, SERVICE_KEY || ANON_KEY, {
  auth: { persistSession: false },
});
const writeClient = APPLY ? createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } }) : null;

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function downloadImage(url) {
  const res = await fetch(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (compatible; NNFoodsImageImport/1.0; +https://nnfoodsandspices.com)' },
  });
  if (!res.ok) throw new Error(`HTTP ${res.status} fetching ${url}`);
  const contentType = res.headers.get('content-type') || '';
  if (!contentType.startsWith('image/')) throw new Error(`Not an image (content-type: ${contentType})`);
  const buf = Buffer.from(await res.arrayBuffer());
  if (buf.length === 0) throw new Error('Empty response body');
  return buf;
}

/** Resize to fit within MAX_LONG_EDGE (no upscaling, no crop, no distortion) and convert to WebP. */
async function processImage(buf) {
  const img = sharp(buf, { failOn: 'error' });
  const meta = await img.metadata();
  if (!meta.width || !meta.height) throw new Error('Could not read image dimensions');
  const webp = await img
    .resize({ width: MAX_LONG_EDGE, height: MAX_LONG_EDGE, fit: 'inside', withoutEnlargement: true })
    .webp({ quality: WEBP_QUALITY })
    .toBuffer();
  const outMeta = await sharp(webp).metadata();
  return { webp, originalDimensions: `${meta.width}x${meta.height}`, outDimensions: `${outMeta.width}x${outMeta.height}` };
}

function extractStoragePath(publicUrl) {
  if (!publicUrl || !publicUrl.includes(`/${BUCKET}/`)) return null;
  return publicUrl.split(`/${BUCKET}/`)[1] || null;
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------
async function main() {
  mkdirSync(PROCESSED_DIR, { recursive: true });

  const sourceMap = JSON.parse(readFileSync(join(__dirname, 'product-image-sources.json'), 'utf8'));
  const bySlug = new Map(sourceMap.products.map((p) => [p.slug, p]));

  console.log(`Mode: ${APPLY ? 'APPLY (will write to Supabase)' : 'DRY RUN (download + process only)'}`);
  console.log(`Fetching current products from Supabase (${SUPABASE_URL})...`);

  const { data: products, error } = await readClient
    .from('products')
    .select('id, slug, name, sku, category_id, image_url, is_active')
    .order('name', { ascending: true });
  if (error) throw new Error(`Failed to read products: ${error.message}`);

  console.log(`Found ${products.length} products in Supabase.\n`);

  // Pre-flight backup of every product's current image state — written
  // before any upload/DB write so a failed run can always be reconciled.
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupPath = join(OUT_DIR, `product_image_backup_before_bulk_import_${timestamp}.json`);
  writeFileSync(
    backupPath,
    JSON.stringify(
      products.map((p) => ({ id: p.id, slug: p.slug, name: p.name, sku: p.sku, image_url: p.image_url })),
      null,
      2,
    ),
  );
  console.log(`Backup written: ${backupPath}\n`);

  const report = [];
  let idx = 0;

  for (const product of products) {
    idx++;
    const match = bySlug.get(product.slug);
    const row = {
      n: idx,
      product: product.name,
      slug: product.slug,
      sku: product.sku,
      sourceFile: match?.file ?? null,
      confidence: match ? match.confidence : 'NOT FOUND',
      action: 'PENDING',
      note: match?.note,
    };

    if (!match) {
      row.action = 'NOT FOUND';
      row.note = 'No entry in product-image-sources.json — needs manual review/upload.';
      report.push(row);
      console.log(`[${idx}/${products.length}] ${product.name} -> NOT FOUND (no source mapping)`);
      continue;
    }

    const sourceUrl = `${sourceMap.sourceBase}/${match.file}`;
    row.sourceUrl = sourceUrl;

    try {
      const raw = await downloadImage(sourceUrl);
      const { webp, originalDimensions, outDimensions } = await processImage(raw);
      row.originalDimensions = originalDimensions;
      row.outDimensions = outDimensions;
      row.outBytes = webp.length;

      const localPath = join(PROCESSED_DIR, `${product.slug}.webp`);
      writeFileSync(localPath, webp);
      row.localPath = localPath;

      if (!APPLY) {
        row.action = 'MATCHED (dry run — not uploaded)';
        report.push(row);
        console.log(`[${idx}/${products.length}] ${product.name}: downloaded + processed (${originalDimensions} -> ${outDimensions}, ${(webp.length / 1024).toFixed(0)} KB)`);
        await sleep(REQUEST_DELAY_MS);
        continue;
      }

      // --apply: upload to a unique path first (never overwrite the object
      // the old image_url points at), verify, THEN update the DB row, and
      // only after that succeeds, best-effort delete the old object.
      const storagePath = `products/${crypto.randomUUID()}.webp`;
      const { error: uploadErr } = await writeClient.storage.from(BUCKET).upload(storagePath, webp, {
        cacheControl: '31536000',
        upsert: false,
        contentType: 'image/webp',
      });
      if (uploadErr) throw new Error(`Storage upload failed: ${uploadErr.message}`);

      const { data: pub } = writeClient.storage.from(BUCKET).getPublicUrl(storagePath);
      const publicUrl = pub.publicUrl;

      // Verify the object is actually publicly reachable before touching the DB.
      const verifyRes = await fetch(publicUrl, { method: 'HEAD' });
      if (!verifyRes.ok) throw new Error(`Uploaded object not reachable: HTTP ${verifyRes.status}`);

      const { error: updateErr } = await writeClient
        .from('products')
        .update({ image_url: publicUrl })
        .eq('id', product.id);
      if (updateErr) throw new Error(`DB update failed (image uploaded but not linked — storage path: ${storagePath}): ${updateErr.message}`);

      row.newImageUrl = publicUrl;
      row.storagePath = storagePath;
      row.action = 'IMPORTED';

      // Best-effort cleanup of the old object, only after the new one is safely linked.
      const oldPath = extractStoragePath(product.image_url);
      if (oldPath) {
        const { error: delErr } = await writeClient.storage.from(BUCKET).remove([oldPath]);
        row.oldImageRemoved = !delErr;
        if (delErr) row.oldImageRemoveError = delErr.message;
      }

      console.log(`[${idx}/${products.length}] ${product.name}: IMPORTED -> ${publicUrl}`);
    } catch (e) {
      row.action = 'FAILED';
      row.error = String(e?.message ?? e);
      console.error(`[${idx}/${products.length}] ${product.name}: FAILED — ${row.error}`);
    }

    report.push(row);
    await sleep(REQUEST_DELAY_MS);
  }

  const reportPath = join(OUT_DIR, `matching-report_${timestamp}.json`);
  writeFileSync(reportPath, JSON.stringify(report, null, 2));

  const summary = report.reduce((acc, r) => {
    acc[r.action] = (acc[r.action] || 0) + 1;
    return acc;
  }, {});

  console.log('\n=== Summary ===');
  console.table(summary);
  console.log(`Full report: ${reportPath}`);
  if (!APPLY) {
    console.log('\nThis was a DRY RUN — nothing was uploaded or written to Supabase.');
    console.log('Review scripts/output/processed/*.webp and the report above, then re-run with --apply.');
  }
}

main().catch((e) => {
  console.error('\nFatal error:', e);
  process.exit(1);
});
