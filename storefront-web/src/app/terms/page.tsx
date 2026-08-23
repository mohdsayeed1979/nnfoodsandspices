import type { Metadata } from 'next';
import { SITE } from '@/lib/constants';

export const metadata: Metadata = {
  title: 'Terms & Conditions',
  description: `Terms & Conditions for the ${SITE.name} website.`,
  alternates: { canonical: '/terms' },
};

export default function TermsPage() {
  return (
    <div className="container-x max-w-3xl py-12">
      <h1 className="font-display text-3xl font-bold text-gray-900">Terms &amp; Conditions</h1>
      <p className="mt-2 text-sm text-gray-500">Effective date: August 2026</p>

      <div className="prose-legal mt-6">
        <p>
          These terms govern your use of the {SITE.name} website, operated by {SITE.legalName}. By
          using this website you agree to them.
        </p>

        <h2>1. Product information</h2>
        <p>
          We aim to keep product details, prices and availability accurate and up to date. Prices are
          shown in Indian Rupees (₹) and may change without prior notice. Product images may be
          representative.
        </p>

        <h2>2. Orders &amp; enquiries</h2>
        <p>
          This website is a catalog. Orders and enquiries are placed via WhatsApp, phone, or email.
          Any order is subject to confirmation and availability, and no contract is formed until we
          confirm it directly with you.
        </p>

        <h2>3. Intellectual property</h2>
        <p>
          The {SITE.name} name, logo, content and product imagery are the property of {SITE.legalName}
          and may not be used without written permission.
        </p>

        <h2>4. Limitation of liability</h2>
        <p>
          This website is provided on an &quot;as is&quot; basis. To the extent permitted by law, we
          are not liable for any indirect or consequential loss arising from its use.
        </p>

        <h2>5. Changes</h2>
        <p>We may update these terms from time to time; continued use of the site constitutes acceptance.</p>

        <h2>6. Contact</h2>
        <p>
          Questions? Email{' '}
          <a className="text-brand-greenDark" href={`mailto:${SITE.email}`}>{SITE.email}</a>.
        </p>
      </div>
    </div>
  );
}
