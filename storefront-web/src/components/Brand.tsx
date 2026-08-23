import Link from 'next/link';
import { SITE } from '@/lib/constants';

export function BrandMark({ size = 40 }: { size?: number }) {
  return (
    <span
      aria-hidden
      className="flex items-center justify-center rounded-xl font-extrabold tracking-tight text-white"
      style={{
        width: size,
        height: size,
        fontSize: size * 0.36,
        background: 'linear-gradient(135deg, #5E9C2C, #3D6E18)',
        boxShadow: '0 6px 16px rgba(94,156,44,0.30)',
      }}
    >
      NN
    </span>
  );
}

export function Logo() {
  return (
    <Link href="/" className="flex items-center gap-2.5">
      <BrandMark size={40} />
      <span className="leading-tight">
        <span className="block font-display text-base font-bold text-gray-900">{SITE.name}</span>
        <span className="block text-[9px] font-semibold uppercase tracking-[0.18em] text-brand-orange">
          {SITE.tagline}
        </span>
      </span>
    </Link>
  );
}
