import Link from 'next/link';
import { BrandMark } from './Brand';
import { SITE } from '@/lib/constants';

export function Footer() {
  return (
    <footer className="mt-16 border-t border-gray-100 bg-brand-cream">
      <div className="container-x grid grid-cols-1 gap-10 py-12 sm:grid-cols-2 lg:grid-cols-4">
        <div>
          <div className="flex items-center gap-2.5">
            <BrandMark size={40} />
            <div>
              <div className="font-display text-base font-bold text-gray-900">{SITE.name}</div>
              <div className="text-[9px] font-semibold uppercase tracking-[0.18em] text-brand-orange">
                {SITE.tagline}
              </div>
            </div>
          </div>
          <p className="mt-4 max-w-xs text-sm leading-relaxed text-gray-600">
            GMP &amp; Halal certified spices and masala blends, crafted from a century-old family
            recipe with no artificial colours or fillers.
          </p>
        </div>

        <div>
          <h4 className="text-sm font-bold text-gray-900">Quick Links</h4>
          <ul className="mt-3 space-y-2 text-sm text-gray-600">
            <li><Link href="/products" className="hover:text-brand-greenDark">Products</Link></li>
            <li><Link href="/categories" className="hover:text-brand-greenDark">Categories</Link></li>
            <li><Link href="/about" className="hover:text-brand-greenDark">About Us</Link></li>
            <li><Link href="/contact" className="hover:text-brand-greenDark">Contact Us</Link></li>
          </ul>
        </div>

        <div>
          <h4 className="text-sm font-bold text-gray-900">Legal</h4>
          <ul className="mt-3 space-y-2 text-sm text-gray-600">
            <li><Link href="/privacy" className="hover:text-brand-greenDark">Privacy Policy</Link></li>
            <li><Link href="/terms" className="hover:text-brand-greenDark">Terms &amp; Conditions</Link></li>
          </ul>
        </div>

        <div>
          <h4 className="text-sm font-bold text-gray-900">Get in Touch</h4>
          <ul className="mt-3 space-y-2 text-sm text-gray-600">
            <li><a href={`tel:${SITE.phone}`} className="hover:text-brand-greenDark">{SITE.phone}</a></li>
            <li><a href={`mailto:${SITE.email}`} className="hover:text-brand-greenDark">{SITE.email}</a></li>
            <li className="text-gray-500">{SITE.address}</li>
          </ul>
          <div className="mt-4 flex gap-3">
            <a href={SITE.social.facebook} target="_blank" rel="noopener noreferrer" className="text-gray-500 hover:text-brand-green" aria-label="Facebook">Facebook</a>
            <a href={SITE.social.instagram} target="_blank" rel="noopener noreferrer" className="text-gray-500 hover:text-brand-green" aria-label="Instagram">Instagram</a>
            <a href={SITE.social.youtube} target="_blank" rel="noopener noreferrer" className="text-gray-500 hover:text-brand-green" aria-label="YouTube">YouTube</a>
          </div>
        </div>
      </div>

      <div className="border-t border-gray-100 py-5">
        <div className="container-x flex flex-col items-center justify-between gap-2 text-xs text-gray-500 sm:flex-row">
          <span>© {new Date().getFullYear()} {SITE.legalName}. All rights reserved.</span>
          <span>{SITE.name}</span>
        </div>
      </div>
    </footer>
  );
}
