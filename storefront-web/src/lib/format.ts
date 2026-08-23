const SYMBOLS: Record<string, string> = { INR: '₹', SAR: 'SAR ', USD: '$', AED: 'AED ' };

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
