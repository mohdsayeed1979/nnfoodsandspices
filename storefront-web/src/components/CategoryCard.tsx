import Link from 'next/link';
import type { Category } from '@/lib/types';

const GRADIENTS: Record<string, string> = {
  'veg-spices': 'linear-gradient(135deg,#7CB342,#4A7D22)',
  'pure-spices': 'linear-gradient(135deg,#F9A825,#EF6C00)',
  'non-veg-spices': 'linear-gradient(135deg,#E64A19,#B0280C)',
  'other-spices': 'linear-gradient(135deg,#FF9E54,#F36B21)',
};

export function CategoryCard({ category }: { category: Category }) {
  const bg = GRADIENTS[category.slug] ?? 'linear-gradient(135deg,#5E9C2C,#3D6E18)';
  return (
    <Link
      href={`/categories/${category.slug}`}
      className="group relative flex min-h-[140px] flex-col justify-end overflow-hidden rounded-2xl p-5 text-white shadow-card transition hover:-translate-y-0.5 hover:shadow-soft"
      style={category.image_url ? undefined : { background: bg }}
    >
      {category.image_url && (
        <>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={category.image_url}
            alt={category.name}
            className="absolute inset-0 h-full w-full object-cover transition duration-300 group-hover:scale-105"
          />
          <span className="absolute inset-0 bg-gradient-to-t from-black/60 to-black/10" />
        </>
      )}
      <div className="relative">
        <h3 className="text-lg font-bold">{category.name}</h3>
        <p className="text-sm text-white/85">{category.product_count ?? 0} products</p>
      </div>
    </Link>
  );
}
