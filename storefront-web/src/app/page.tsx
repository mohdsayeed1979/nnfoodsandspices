import Link from 'next/link';
import { getCategories, getFeaturedProducts, getPopularProducts } from '@/lib/catalog';
import { ProductCard } from '@/components/ProductCard';
import { CategoryCard } from '@/components/CategoryCard';
import { SectionHeading } from '@/components/SectionHeading';
import { SITE, whatsappLink } from '@/lib/constants';

export const dynamic = 'force-dynamic';

const WHY = [
  { t: '100% Natural', d: 'No artificial colours, flavours or fillers — ever.', i: '🌿' },
  { t: 'GMP & Halal Certified', d: 'Every blend meets strict quality standards.', i: '✓' },
  { t: '100+ Years of Blending', d: 'Family recipes perfected over generations.', i: '🏆' },
  { t: 'Freshly Packed', d: 'Ground and packed close to dispatch for aroma.', i: '📦' },
];

export default async function HomePage() {
  const [categories, featured, popular] = await Promise.all([
    getCategories(),
    getFeaturedProducts(8),
    getPopularProducts(8),
  ]);

  return (
    <>
      {/* Hero */}
      <section className="relative overflow-hidden bg-gradient-to-br from-brand-green to-brand-greenDark text-white">
        <div className="absolute -right-16 -top-16 h-72 w-72 rounded-full bg-white/10 blur-2xl" />
        <div className="absolute -bottom-24 left-10 h-72 w-72 rounded-full bg-brand-orange/20 blur-3xl" />
        <div className="container-x relative grid gap-8 py-16 md:grid-cols-2 md:py-24">
          <div className="flex flex-col justify-center">
            <span className="chip w-fit bg-white/15 text-white ring-1 ring-white/25">
              {SITE.legalName}
            </span>
            <h1 className="mt-4 font-display text-4xl font-extrabold leading-tight sm:text-5xl">
              100% Naturally <span className="text-brand-orangeLight">Pure Spices</span>
            </h1>
            <p className="mt-4 max-w-md text-white/90">
              Handcrafted masala blends and single-origin spices — GMP &amp; Halal certified,
              blended from a century-old family recipe.
            </p>
            <div className="mt-7 flex flex-wrap gap-3">
              <Link href="/products" className="btn bg-white text-brand-greenDark hover:bg-white/90">
                Shop Products
              </Link>
              <a href={whatsappLink()} target="_blank" rel="noopener noreferrer" className="btn-whatsapp">
                Order on WhatsApp
              </a>
            </div>
          </div>
          <div className="hidden items-center justify-center md:flex">
            <div className="grid grid-cols-2 gap-4">
              {['🌶️', '🧄', '🌿', '🍛'].map((e, i) => (
                <div
                  key={i}
                  className="flex h-32 w-32 items-center justify-center rounded-3xl bg-white/10 text-5xl ring-1 ring-white/15 backdrop-blur"
                >
                  {e}
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Categories */}
      {categories.length > 0 && (
        <section className="container-x py-14">
          <SectionHeading title="Shop by Category" subtitle="Explore our spice collections" href="/categories" />
          <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
            {categories.map((c) => (
              <CategoryCard key={c.id} category={c} />
            ))}
          </div>
        </section>
      )}

      {/* Featured */}
      {featured.length > 0 && (
        <section className="bg-brand-cream py-14">
          <div className="container-x">
            <SectionHeading title="Featured Products" subtitle="Hand-picked favourites" href="/products?featured=1" />
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
              {featured.map((p) => (
                <ProductCard key={p.id} product={p} />
              ))}
            </div>
          </div>
        </section>
      )}

      {/* Why choose us */}
      <section className="container-x py-14">
        <SectionHeading title="Why Choose NN Foods & Spices" />
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {WHY.map((w) => (
            <div key={w.t} className="card p-6">
              <div className="text-3xl">{w.i}</div>
              <h3 className="mt-3 font-semibold text-gray-900">{w.t}</h3>
              <p className="mt-1 text-sm text-gray-500">{w.d}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Quality band */}
      <section className="bg-gradient-to-r from-brand-orange to-brand-orangeLight py-12 text-white">
        <div className="container-x flex flex-col items-center gap-4 text-center">
          <h2 className="font-display text-2xl font-bold sm:text-3xl">Purity you can taste</h2>
          <p className="max-w-2xl text-white/90">
            From our kitchen to yours — sourced, blended and packed with care so every dish carries
            the authentic aroma and flavour of naturally pure spices.
          </p>
        </div>
      </section>

      {/* Popular */}
      {popular.length > 0 && (
        <section className="container-x py-14">
          <SectionHeading title="Popular Products" subtitle="Loved by our customers" href="/products" />
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            {popular.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        </section>
      )}

      {/* About teaser */}
      <section className="bg-brand-cream py-14">
        <div className="container-x grid items-center gap-8 md:grid-cols-2">
          <div>
            <h2 className="font-display text-2xl font-bold text-gray-900 sm:text-3xl">
              A century of blending tradition
            </h2>
            <p className="mt-3 text-sm leading-relaxed text-gray-600">
              {SITE.legalName} has mastered the art of blending spices for over 100 years —
              combining traditional recipes with strict modern quality standards to bring you
              100% naturally pure spices.
            </p>
            <Link href="/about" className="btn-outline mt-6">Learn more about us</Link>
          </div>
          <div className="grid grid-cols-3 gap-4">
            {[['100+', 'Years'], ['48+', 'Products'], ['4', 'Categories']].map(([n, l]) => (
              <div key={l} className="card p-5 text-center">
                <div className="text-2xl font-extrabold text-brand-greenDark">{n}</div>
                <div className="text-xs text-gray-500">{l}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Contact CTA */}
      <section className="container-x py-14">
        <div className="rounded-3xl bg-brand-green px-6 py-10 text-center text-white sm:px-10">
          <h2 className="font-display text-2xl font-bold sm:text-3xl">Have a question or bulk order?</h2>
          <p className="mx-auto mt-2 max-w-xl text-white/90">
            Talk to us on WhatsApp or reach our customer care — we&apos;re happy to help.
          </p>
          <div className="mt-6 flex flex-wrap justify-center gap-3">
            <a href={whatsappLink()} target="_blank" rel="noopener noreferrer" className="btn-whatsapp">Chat on WhatsApp</a>
            <Link href="/contact" className="btn bg-white text-brand-greenDark hover:bg-white/90">Contact Us</Link>
          </div>
        </div>
      </section>
    </>
  );
}
