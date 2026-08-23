// ============================================================================
// bootstrap-admin.mjs — creates (or verifies) the initial NN Foods admin user.
//
// SECURITY: this script needs the Supabase SERVICE-ROLE key and the admin
// password. Both are read from environment variables (or a LOCAL, gitignored
// .env.local). They are NEVER committed and NEVER shipped to the browser.
//
// Usage (from admin-web/):
//   1. cp .env.example .env.local   and fill in real values
//   2. npm install
//   3. npm run bootstrap-admin
//
// Idempotent: safe to run repeatedly. If the user already exists it is NOT
// duplicated and its password is NOT overwritten — only its admin role is
// (re)ensured.
// ============================================================================

import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { createClient } from '@supabase/supabase-js';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Minimal .env.local loader (no dependency).
function loadEnvLocal() {
  const p = join(__dirname, '..', '.env.local');
  if (!existsSync(p)) return;
  for (const line of readFileSync(p, 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m && !process.env[m[1]]) {
      process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
    }
  }
}
loadEnvLocal();

const URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const EMAIL = process.env.ADMIN_EMAIL;
const PASSWORD = process.env.ADMIN_PASSWORD;
const FULL_NAME = process.env.ADMIN_FULL_NAME || 'NN Foods Admin';

function fail(msg) {
  console.error(`\n✗ ${msg}\n`);
  process.exit(1);
}

if (!URL) fail('NEXT_PUBLIC_SUPABASE_URL is not set.');
if (!SERVICE_KEY) fail('SUPABASE_SERVICE_ROLE_KEY is not set (server-only secret).');
if (!EMAIL) fail('ADMIN_EMAIL is not set.');
if (!PASSWORD) fail('ADMIN_PASSWORD is not set.');

const admin = createClient(URL, SERVICE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

async function findUserByEmail(email) {
  // Paginate through users (fine for small user counts).
  for (let page = 1; page <= 20; page++) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 200 });
    if (error) throw error;
    const match = data.users.find((u) => u.email?.toLowerCase() === email.toLowerCase());
    if (match) return match;
    if (data.users.length < 200) break;
  }
  return null;
}

async function main() {
  console.log(`\n→ Bootstrapping admin ${EMAIL} on ${URL}`);

  let user = await findUserByEmail(EMAIL);

  if (user) {
    console.log('• Auth user already exists — not duplicating, not resetting password.');
  } else {
    const { data, error } = await admin.auth.admin.createUser({
      email: EMAIL,
      password: PASSWORD,
      email_confirm: true,
      user_metadata: { full_name: FULL_NAME },
    });
    if (error) fail(`Failed to create auth user: ${error.message}`);
    user = data.user;
    console.log('• Created auth user.');
  }

  // Ensure the profile row exists and has admin role + active.
  const { error: upsertErr } = await admin.from('profiles').upsert(
    {
      id: user.id,
      email: EMAIL,
      full_name: FULL_NAME,
      role: 'admin',
      is_active: true,
    },
    { onConflict: 'id' },
  );
  if (upsertErr) fail(`Failed to upsert admin profile: ${upsertErr.message}`);

  console.log('• Ensured profile role=admin, is_active=true.');
  console.log('\n✓ Done. Admin can now sign in at /admin/login.\n');
}

main().catch((e) => fail(e.message ?? String(e)));
