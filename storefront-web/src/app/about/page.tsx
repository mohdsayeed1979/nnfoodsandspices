import type { Metadata } from 'next';
import Link from 'next/link';
import { SITE, whatsappLink } from '@/lib/constants';

export const metadata: Metadata = {
  title: 'About Us',
  description: `About ${SITE.legalName} — a century of blending 100% naturally pure, GMP & Halal certified spices.`,
  alternates: { canonical: '/about' },
};

const VALUES = [
  { t: '100% Natural', d: 'No artificial colours, flavours or fillers in any blend.' },
  { t: 'Certified Quality', d: 'GMP and Halal certified processes end to end.' },
  { t: 'Family Tradition', d: 'Recipes refined across generations of blenders.' },
];

export default function AboutPage() {
  return (
    <div>
      <section className="bg-gradient-to-br from-brand-green to-brand-greenDark py-16 text-white">
        <div className="container-x">
          <h1 className="font-display text-4xl font-extrabold">About {SITE.name}</h1>
          <p className="mt-3 max-w-2xl text-white/90">{SITE.tagline}</p>
        </div>
      </section>

      <section className="container-x py-14">
        <div className="grid gap-10 md:grid-cols-2">
          <div>
            <h2 className="font-display text-2xl font-bold text-gray-900">Our Story</h2>
            <p className="mt-3 text-sm leading-relaxed text-gray-600">
              {SITE.legalName} has mastered the art of blending spices for over 100 years —
              combining traditional recipes with strict modern quality standards to bring you
              100% naturally pure spices, free from artificial colours and fillers.
            </p>
            <p className="mt-3 text-sm leading-relaxed text-gray-600">
              Every product is GMP and Halal certified, ground and packed close to dispatch to
              preserve freshness and aroma — from our kitchen to yours.
            </p>
          </div>
          <div className="grid grid-cols-3 gap-4 self-start">
            {[['100+', 'Years of blending'], ['48+', 'Spice blends'], ['4', 'Categories']].map(([n, l]) => (
              <div key={l} className="card p-5 text-center">
                <div className="text-2xl font-extrabold text-brand-greenDark">{n}</div>
                <div className="mt-1 text-xs text-gray-500">{l}</div>
              </div>
            ))}
          </div>
        </div>

        <div className="mt-14">
          <h2 className="font-display text-2xl font-bold text-gray-900">Our Values</h2>
          <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-3">
            {VALUES.map((v) => (
              <div key={v.t} className="card p-6">
                <h3 className="font-semibold text-gray-900">{v.t}</h3>
                <p className="mt-1 text-sm text-gray-500">{v.d}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="mt-14 flex flex-wrap gap-3">
          <Link href="/products" className="btn-primary">Browse Products</Link>
          <a href={whatsappLink()} target="_blank" rel="noopener noreferrer" className="btn-whatsapp">
            Chat on WhatsApp
          </a>
        </div>
      </section>
    </div>
  );
}
