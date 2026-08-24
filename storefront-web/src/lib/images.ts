const BUCKET = 'product-images';

/**
 * Resolves a stored product image value to a loadable public URL.
 *
 * The admin panel stores the FULL Supabase public URL in `image_url`, so the
 * common case is a value that already starts with http(s). As a safety net
 * this also accepts a bare storage path (e.g. "products/abc.webp") and builds
 * the public URL from NEXT_PUBLIC_SUPABASE_URL — never hard-coded. Returns ''
 * when there is genuinely no image, so callers can show the branded fallback.
 */
export function resolveImageUrl(value: string | null | undefined): string {
  const v = (value ?? '').trim();
  if (!v) return '';
  if (v.startsWith('http://') || v.startsWith('https://')) return v;
  const base = process.env.NEXT_PUBLIC_SUPABASE_URL?.replace(/\/$/, '');
  if (!base) return '';
  const path = v.replace(/^\/+/, '');
  return `${base}/storage/v1/object/public/${BUCKET}/${path}`;
}
