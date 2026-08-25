import type { PackPrice } from './types';

const SYMBOLS: Record<string, string> = { INR: '₹', SAR: 'SAR ', USD: '$', AED: 'AED ' };

/** Standard pack multipliers relative to the 100g base selling price — a
 * fallback used only when the DB row has no explicit per-size prices (legacy
 * plain-string pack_sizes). Kept identical to the Flutter app's ladder. */
export const PACK_MULTIPLIERS: Record<string, number> = {
  '100g': 1.0,
  '250g': 2.3,
  '500g': 4.4,
  '1kg': 8.0,
};

/**
 * Normalizes the DB `pack_sizes` jsonb into PackPrice[]. Accepts the new
 * shape [{size, price}] (real prices) or a legacy plain-string array
 * ["100g", ...], in which case prices are derived from the base via the
 * multiplier ladder. Empty/invalid input yields the standard four sizes.
 */
export function packPricesFrom(raw: unknown, base: number): PackPrice[] {
  const out: PackPrice[] = [];
  if (Array.isArray(raw)) {
    for (const entry of raw) {
      if (entry && typeof entry === 'object' && 'size' in entry) {
        const size = String((entry as any).size ?? '');
        const price = Number((entry as any).price);
        if (size) out.push({ size, price: Number.isFinite(price) ? price : base });
      } else if (typeof entry === 'string' && entry) {
        out.push({ size: entry, price: Math.round(base * (PACK_MULTIPLIERS[entry] ?? 1)) });
      }
    }
  }
  if (out.length === 0) {
    for (const [size, mult] of Object.entries(PACK_MULTIPLIERS)) {
      out.push({ size, price: Math.round(base * mult) });
    }
  }
  return out;
}

/** Selling price for a given pack size, falling back to the base price. */
export function priceForSize(packs: PackPrice[], size: string, fallback: number): number {
  return packs.find((p) => p.size === size)?.price ?? fallback;
}

/** Formats a price with its currency symbol (defaults to ₹ INR). */
export function formatPrice(amount: number | null | undefined, currency = 'INR'): string {
  if (amount === null || amount === undefined) return '';
  const sym = SYMBOLS[currency] ?? `${currency} `;
  const n = Number(amount);
  const body = Number.isInteger(n) ? n.toString() : n.toFixed(2);
  return `${sym}${body}`;
}

/** The customer-facing selling price = sale_price when present, else price. */
export function sellingPrice(p: { price: number; sale_price: number | null }): number {
  return p.sale_price ?? p.price;
}

export function hasDiscount(p: { price: number; sale_price: number | null }): boolean {
  return p.sale_price != null && p.sale_price < p.price;
}

export function discountPercent(p: { price: number; sale_price: number | null }): number {
  if (!hasDiscount(p)) return 0;
  return Math.round(((p.price - (p.sale_price as number)) / p.price) * 100);
}

export function initials(name: string): string {
  const words = name.trim().split(/\s+/);
  if (words.length === 1) return words[0].slice(0, 2).toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}
