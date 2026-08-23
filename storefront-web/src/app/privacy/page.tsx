import type { Metadata } from 'next';
import { SITE } from '@/lib/constants';

export const metadata: Metadata = {
  title: 'Privacy Policy',
  description: `Privacy Policy for the ${SITE.name} website.`,
  alternates: { canonical: '/privacy' },
};

export default function PrivacyPage() {
  return (
    <div className="container-x max-w-3xl py-12">
      <h1 className="font-display text-3xl font-bold text-gray-900">Privacy Policy</h1>
      <p className="mt-2 text-sm text-gray-500">Effective date: August 2026</p>

      <div className="prose-legal mt-6">
        <p>
          {SITE.legalName} (&quot;we&quot;, &quot;us&quot;) operates the {SITE.name} website. This
          policy explains what limited information this website handles.
        </p>

        <h2>Information we handle</h2>
        <p>
          This website is a product catalog. It does not require you to create an account and does
          not process payments on-site — orders and enquiries are made via WhatsApp, phone, or
          email, using contact details you choose to share directly with us.
        </p>
        <ul>
          <li>We do not collect names, addresses, or payment details through this website.</li>
          <li>
            Standard, privacy-respecting analytics may record anonymous, aggregate usage (such as
            page views) to help us improve the site. This is not used to identify you.
          </li>
          <li>Product images are served from our secure storage; no login is required to view them.</li>
        </ul>

        <h2>Third-party services</h2>
        <p>
          Product and category data is served from Supabase (our catalog backend). Maps are embedded
          from Google Maps, and WhatsApp links open WhatsApp. Each third party processes data under
          its own privacy policy.
        </p>

        <h2>Data security</h2>
        <p>
          All traffic to this website is served over HTTPS. Administrative access to our catalog is
          protected and never exposed on this public website.
        </p>

        <h2>Children&apos;s privacy</h2>
        <p>This website is not directed at children and does not knowingly collect their data.</p>

        <h2>Contact</h2>
        <p>
          Questions about this policy? Email{' '}
          <a className="text-brand-greenDark" href={`mailto:${SITE.email}`}>{SITE.email}</a>.
        </p>

        <h2>Updates</h2>
        <p>We may update this policy from time to time; the effective date above reflects the latest revision.</p>
      </div>
    </div>
  );
}
