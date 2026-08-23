import Link from 'next/link';

export function SectionHeading({
  title,
  subtitle,
  href,
  hrefLabel = 'View all',
}: {
  title: string;
  subtitle?: string;
  href?: string;
  hrefLabel?: string;
}) {
  return (
    <div className="mb-6 flex items-end justify-between gap-4">
      <div>
        <h2 className="font-display text-2xl font-bold text-gray-900 sm:text-3xl">{title}</h2>
        {subtitle && <p className="mt-1 text-sm text-gray-500">{subtitle}</p>}
      </div>
      {href && (
        <Link href={href} className="shrink-0 text-sm font-semibold text-brand-greenDark hover:underline">
          {hrefLabel} →
        </Link>
      )}
    </div>
  );
}
