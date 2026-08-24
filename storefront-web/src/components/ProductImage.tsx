/* eslint-disable @next/next/no-img-element */
// Intentional plain <img> for Supabase Storage URLs: avoids next/image's
// remote-loader cost while still lazy-loading below the fold.
import { initials } from '@/lib/format';
import { resolveImageUrl } from '@/lib/images';

const PALETTE: Record<string, [string, string]> = {
  'veg-spices': ['#7CB342', '#4A7D22'],
  'pure-spices': ['#F9A825', '#EF6C00'],
  'non-veg-spices': ['#E64A19', '#B0280C'],
  'other-spices': ['#FF9E54', '#F36B21'],
};

/**
 * Renders a real product photo when image_url is a live URL; otherwise a
 * premium, brand-consistent placeholder (category-tinted gradient + initials)
 * so the storefront looks polished even before an admin uploads photos.
 */
export function ProductImage({
  src,
  name,
  categorySlug,
  className = '',
  sizes,
  priority,
}: {
  src: string;
  name: string;
  categorySlug?: string;
  className?: string;
  sizes?: string;
  priority?: boolean;
}) {
  const url = resolveImageUrl(src);
  if (url) {
    return (
      <img
        src={url}
        alt={name}
        loading={priority ? 'eager' : 'lazy'}
        sizes={sizes}
        className={`h-full w-full object-cover ${className}`}
      />
    );
  }
  const [a, b] = PALETTE[categorySlug ?? ''] ?? ['#8BC34A', '#5E9C2C'];
  return (
    <div
      className={`flex h-full w-full items-center justify-center ${className}`}
      style={{ background: `linear-gradient(135deg, ${a}, ${b})` }}
      role="img"
      aria-label={name}
    >
      <span className="select-none text-2xl font-extrabold tracking-wide text-white/90">
        {initials(name)}
      </span>
    </div>
  );
}
