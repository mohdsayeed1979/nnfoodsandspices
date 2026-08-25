'use client';

import { useState } from 'react';
import type { PackPrice } from '@/lib/types';
import { formatPrice } from '@/lib/format';
import { whatsappLink } from '@/lib/constants';

/**
 * Client-side pack-size picker for the product detail page. Selecting a size
 * updates the displayed price (and the scaled strikethrough) and rebuilds the
 * WhatsApp order message with the chosen size + price. Prices come straight
 * from the shared Supabase `pack_prices` — the same source the mobile app
 * uses — so the two never diverge.
 */
export function PackSizeSelector({
  productName,
  packs,
  currency,
  basePrice,
  baseCompareAt,
}: {
  productName: string;
  packs: PackPrice[];
  currency: string;
  /** 100g selling price — the reference the strikethrough ratio scales from. */
  basePrice: number;
  /** 100g struck-through original price, or null when not discounted. */
  baseCompareAt: number | null;
}) {
  const [selected, setSelected] = useState(packs[0]?.size ?? '');
  const active = packs.find((p) => p.size === selected) ?? packs[0];
  const price = active?.price ?? basePrice;

  // Scale the 100g strikethrough by this size's ratio so the discount %
  // stays consistent across sizes (matches the Flutter app).
  const compareAt =
    baseCompareAt != null && basePrice > 0
      ? Math.round(baseCompareAt * (price / basePrice))
      : null;
  const discountPct =
    compareAt != null && compareAt > price
      ? Math.round(((compareAt - price) / compareAt) * 100)
      : 0;

  const orderMessage =
    `Hi NN Foods & Spices, I'd like to order: ${productName} — ${selected} ` +
    `(${formatPrice(price, currency)}).`;

  return (
    <div>
      <div className="mt-4 flex items-baseline gap-3">
        <span className="text-3xl font-extrabold text-brand-greenDark">
          {formatPrice(price, currency)}
        </span>
        {compareAt != null && discountPct > 0 && (
          <>
            <span className="text-lg text-gray-400 line-through">
              {formatPrice(compareAt, currency)}
            </span>
            <span className="chip bg-brand-orange/10 text-brand-orange">{discountPct}% OFF</span>
          </>
        )}
      </div>

      {packs.length > 0 && (
        <div className="mt-6">
          <h2 className="text-sm font-bold text-gray-900">Pack Size</h2>
          <div className="mt-2 flex flex-wrap gap-2" role="group" aria-label="Pack size">
            {packs.map((p) => {
              const isActive = p.size === selected;
              return (
                <button
                  key={p.size}
                  type="button"
                  onClick={() => setSelected(p.size)}
                  aria-pressed={isActive}
                  className={`min-w-[68px] rounded-xl border px-4 py-2 text-sm font-semibold transition ${
                    isActive
                      ? 'border-brand-green bg-brand-green text-white shadow-soft'
                      : 'border-gray-200 bg-white text-gray-700 hover:border-brand-green/60'
                  }`}
                >
                  <span className="block">{p.size}</span>
                  <span className={`block text-xs font-medium ${isActive ? 'text-white/90' : 'text-gray-400'}`}>
                    {formatPrice(p.price, currency)}
                  </span>
                </button>
              );
            })}
          </div>
        </div>
      )}

      <div className="mt-6 flex flex-wrap gap-3">
        <a
          href={whatsappLink(orderMessage)}
          target="_blank"
          rel="noopener noreferrer"
          className="btn-whatsapp"
        >
          Order on WhatsApp
        </a>
      </div>
    </div>
  );
}
