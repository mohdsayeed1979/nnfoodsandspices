// Real NN Foods & Spices company info (from the existing project — not invented).
export const SITE = {
  name: 'NN Foods & Spices',
  legalName: "Nujju's Nest Spices Pvt. Ltd.",
  tagline: '100% NATURALLY PURE SPICES',
  description:
    'NN Foods & Spices — 100% naturally pure spices and masala blends by ' +
    "Nujju's Nest Spices Pvt. Ltd. GMP & Halal certified, blended from a " +
    'century-old family recipe with no artificial colours or fillers.',
  email: 'nnfoodandspices@gmail.com',
  phone: '+919701973386',
  whatsapp: '919701973386',
  address:
    'Door No.8-3/161/A/1, Balaji Enclaves II, Thondu Pally, Shamshabad, ' +
    'Ranga Reddy District, Telangana, India 501218',
  website: 'https://nnfoodsandspices.com',
  social: {
    facebook: 'https://facebook.com/nnfoodandspices',
    instagram: 'https://instagram.com/nnfoodandspices/',
    youtube: 'https://youtube.com/@anzanz314',
  },
} as const;

export function siteUrl(): string {
  return (
    process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, '') ||
    'https://nnfoodsandspices-web.vercel.app'
  );
}

export function whatsappLink(message?: string): string {
  const text = message ?? "Hi NN Foods & Spices, I'd like to know more about your products.";
  return `https://wa.me/${SITE.whatsapp}?text=${encodeURIComponent(text)}`;
}
