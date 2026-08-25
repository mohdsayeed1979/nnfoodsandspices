import Link from 'next/link';
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { getProductBySlug, getRelatedProducts } from '@/lib/catalog';
import { ProductImage } from '@/components/ProductImage';
import { ProductCard } from '@/components/ProductCard';
import { PackSizeSelector } from '@/components/PackSizeSelector';
import { formatPrice, hasDiscount, sellingPrice } from '@/lib/format';
import { STOCK_LABELS } from '@/lib/types';
import { SITE, siteUrl } from '@/lib/constants';

export const dynamic = 'force-dynamic';

export async function generateMetadata({
  params,
}: {
  params: { slug: string };
}): Promise<Metadata> {
  const product = await getProductBySlug(params.slug);
  if (!product) return { title: 'Product not found' };
  const price = formatPrice(sellingPrice(product), product.currency);
  const desc = product.short_description || `${product.name} — ${price}. ${SITE.tagline}.`;
  return {
    title: product.name,
    description: desc,
    alternates: { canonical: `/products/${product.slug}` },
    openGraph: {
      title: `${product.name} — ${SITE.name}`,
      description: desc,
      url: `${siteUrl()}/products/${product.slug}`,
      images: product.image_url ? [{ url: product.image_url }] : undefined,
      type: 'website',
    },
  };
}

export default async function ProductDetailPage({ params }: { params: { slug: string } }) {
  const product = await getProductBySlug(params.slug);
  if (!product) notFound();

  const related = await getRelatedProducts(product.category?.slug, product.slug, 4);
  const gallery = [product.image_url, ...product.additional_images].filter(Boolean);
  const baseSelling = sellingPrice(product);
  const baseCompareAt = hasDiscount(product) ? product.price : null;

  const specs: [string, string][] = [
    ['SKU', product.sku ?? '—'],
    ['Category', product.category?.name ?? '—'],
    ['Type', product.is_veg ? 'Vegetarian' : 'Non-Vegetarian'],
    ['Availability', STOCK_LABELS[product.stock_status]],
    ['Certification', 'GMP & Halal Certified'],
  ];

  return (
    <div className="container-x py-8">
      <nav className="text-xs text-gray-500">
        <Link href="/" className="hover:text-brand-greenDark">Home</Link> ·{' '}
        <Link href="/products" className="hover:text-brand-greenDark">Products</Link>
        {product.category && (
          <>
            {' '}·{' '}
            <Link href={`/categories/${product.category.slug}`} className="hover:text-brand-greenDark">
              {product.category.name}
            </Link>
          </>
        )}{' '}
        · <span className="text-gray-700">{product.name}</span>
      </nav>

      <div className="mt-6 grid gap-8 md:grid-cols-2">
        {/* Gallery */}
        <div>
          <div className="aspect-square overflow-hidden rounded-2xl border border-gray-100 bg-gray-50">
            <ProductImage
              src={product.image_url}
              name={product.name}
              categorySlug={product.category?.slug}
              priority
              sizes="(max-width: 768px) 100vw, 50vw"
            />
          </div>
          {gallery.length > 1 && (
            <div className="mt-3 flex gap-3">
              {gallery.slice(0, 4).map((src, i) => (
                <div key={i} className="h-16 w-16 overflow-hidden rounded-lg border border-gray-100 bg-gray-50">
                  <ProductImage src={src} name={product.name} categorySlug={product.category?.slug} />
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Info */}
        <div className="flex flex-col">
          <div className="flex items-center gap-2">
            {product.category && (
              <span className="chip bg-brand-green/10 text-brand-greenDark">{product.category.name}</span>
            )}
            {product.is_featured && <span className="chip bg-brand-orange text-white">Featured</span>}
          </div>
          <h1 className="mt-3 font-display text-3xl font-bold text-gray-900">{product.name}</h1>

          <PackSizeSelector
            productName={product.name}
            packs={product.pack_prices}
            currency={product.currency}
            basePrice={baseSelling}
            baseCompareAt={baseCompareAt}
          />

          <span
            className={`mt-4 block text-sm font-semibold ${product.stock_status === 'in_stock' ? 'text-brand-green' : 'text-gray-500'}`}
          >
            {STOCK_LABELS[product.stock_status]}
          </span>

          {product.short_description && (
            <p className="mt-4 text-sm text-gray-600">{product.short_description}</p>
          )}

          <div className="mt-6">
            <Link href="/contact" className="btn-outline">Contact Us</Link>
          </div>

          {product.description && (
            <div className="mt-8">
              <h2 className="text-sm font-bold text-gray-900">Description</h2>
              <p className="mt-2 text-sm leading-relaxed text-gray-600">{product.description}</p>
            </div>
          )}

          <div className="mt-8">
            <h2 className="text-sm font-bold text-gray-900">Product Information</h2>
            <dl className="mt-2 overflow-hidden rounded-xl border border-gray-100">
              {specs.map(([k, v], i) => (
                <div key={k} className={`flex px-4 py-2.5 text-sm ${i % 2 ? 'bg-white' : 'bg-gray-50'}`}>
                  <dt className="w-40 text-gray-500">{k}</dt>
                  <dd className="font-medium text-gray-800">{v}</dd>
                </div>
              ))}
            </dl>
          </div>
        </div>
      </div>

      {related.length > 0 && (
        <section className="mt-16">
          <h2 className="font-display text-2xl font-bold text-gray-900">Related Products</h2>
          <div className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            {related.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
