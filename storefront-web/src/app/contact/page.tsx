import type { Metadata } from 'next';
import { SITE, whatsappLink } from '@/lib/constants';

export const metadata: Metadata = {
  title: 'Contact Us',
  description: `Contact ${SITE.name} — customer care, WhatsApp, email and address.`,
  alternates: { canonical: '/contact' },
};

const mapsQuery =
  'Nujju%27s+Nest+Spices+Pvt+Ltd+Shamshabad+Telangana+501218';

export default function ContactPage() {
  const rows: { label: string; value: string; href?: string }[] = [
    { label: 'Customer Care', value: SITE.phone, href: `tel:${SITE.phone}` },
    { label: 'Email', value: SITE.email, href: `mailto:${SITE.email}` },
    { label: 'WhatsApp', value: `+${SITE.whatsapp}`, href: whatsappLink() },
    { label: 'Website', value: SITE.website, href: SITE.website },
  ];

  return (
    <div className="container-x py-12">
      <h1 className="font-display text-3xl font-bold text-gray-900">Contact Us</h1>
      <p className="mt-1 text-sm text-gray-500">We&apos;d love to hear from you.</p>

      <div className="mt-8 grid gap-8 md:grid-cols-2">
        <div className="card p-6">
          <h2 className="font-semibold text-gray-900">{SITE.legalName}</h2>
          <p className="mt-2 text-sm leading-relaxed text-gray-600">{SITE.address}</p>

          <dl className="mt-6 space-y-3">
            {rows.map((r) => (
              <div key={r.label} className="flex items-center justify-between gap-4 text-sm">
                <dt className="text-gray-500">{r.label}</dt>
                <dd className="font-medium text-gray-800">
                  {r.href ? (
                    <a
                      href={r.href}
                      target={r.href.startsWith('http') ? '_blank' : undefined}
                      rel="noopener noreferrer"
                      className="text-brand-greenDark hover:underline"
                    >
                      {r.value}
                    </a>
                  ) : (
                    r.value
                  )}
                </dd>
              </div>
            ))}
          </dl>

          <div className="mt-6 flex flex-wrap gap-3">
            <a href={whatsappLink()} target="_blank" rel="noopener noreferrer" className="btn-whatsapp">
              Chat on WhatsApp
            </a>
            <a
              href={`https://www.google.com/maps/search/?api=1&query=${mapsQuery}`}
              target="_blank"
              rel="noopener noreferrer"
              className="btn-outline"
            >
              Find us on Maps
            </a>
          </div>

          <div className="mt-6 flex gap-4 text-sm">
            <a href={SITE.social.facebook} target="_blank" rel="noopener noreferrer" className="text-gray-500 hover:text-brand-green">Facebook</a>
            <a href={SITE.social.instagram} target="_blank" rel="noopener noreferrer" className="text-gray-500 hover:text-brand-green">Instagram</a>
            <a href={SITE.social.youtube} target="_blank" rel="noopener noreferrer" className="text-gray-500 hover:text-brand-green">YouTube</a>
          </div>
        </div>

        <div className="overflow-hidden rounded-2xl border border-gray-100">
          <iframe
            title="NN Foods & Spices location"
            className="h-full min-h-[320px] w-full"
            loading="lazy"
            referrerPolicy="no-referrer-when-downgrade"
            src={`https://www.google.com/maps?q=${mapsQuery}&output=embed`}
          />
        </div>
      </div>
    </div>
  );
}
