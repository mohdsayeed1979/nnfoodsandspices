const SYMBOLS: Record<string, string> = { SAR: 'SAR ', INR: '₹', USD: '$', AED: 'AED ' };

export function formatPrice(amount: number | null | undefined, currency = 'SAR'): string {
  if (amount === null || amount === undefined) return '—';
  const sym = SYMBOLS[currency] ?? `${currency} `;
  return `${sym}${Number(amount).toFixed(2)}`;
}

export function formatDate(iso: string | null | undefined): string {
  if (!iso) return '—';
  try {
    return new Date(iso).toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  } catch {
    return '—';
  }
}

/** Deterministic slug from a product/category name. */
export function slugify(name: string): string {
  return name
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}
