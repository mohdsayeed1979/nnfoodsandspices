import Link from 'next/link';
import type { Product } from '@/lib/types';
import { ProductImage } from './ProductImage';
import { discountPercent, formatPrice, hasDiscount, sellingPrice } from '@/lib/format';

export function ProductCard({ product }: { product: Product }) {
  const discount = hasDiscount(product);
  return (
    <Link
      href={`/products/${product.slug}`}
      className="card group flex flex-col transition hover:-translate-y-0.5 hover:shadow-soft"
    >
      <div className="relative aspect-square overflow-hidden bg-gray-50">
        <ProductImage
          src={product.image_url}
          name={product.name}
          categorySlug={product.category?.slug}
          sizes="(max-width: 640px) 50vw, 25vw"
          className="transition duration-300 group-hover:scale-105"
        />
        {product.is_featured && (
          <span className="chip absolute left-2 top-2 bg-brand-orange text-white">Featured</span>
        )}
        {discount && (
          <span className="chip absolute right-2 top-2 bg-brand-greenDark text-white">
            {discountPercent(product)}% OFF
          </span>
        )}
      </div>
      <div className="flex flex-1 flex-col p-3.5">
        {product.category && (
          <span className="text-[11px] font-semibold uppercase tracking-wide text-brand-orange">
            {product.category.name}
          </span>
        )}
        <h3 className="mt-0.5 line-clamp-2 text-sm font-semibold text-gray-900">{product.name}</h3>
        <div className="mt-auto flex items-baseline gap-2 pt-2">
          <span className="text-base font-bold text-brand-greenDark">
            {formatPrice(sellingPrice(product), product.currency)}
          </span>
          {discount && (
            <span className="text-xs text-gray-400 line-through">
              {formatPrice(product.price, product.currency)}
            </span>
          )}
        </div>
      </div>
    </Link>
  );
}
