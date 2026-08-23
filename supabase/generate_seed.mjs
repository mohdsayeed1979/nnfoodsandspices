// Generates 004_seed_catalog.sql from the exact same formula used by the
// Flutter app's ProductSeedData (_buildGroup). Keeping the generator here
// guarantees the Supabase seed matches the deployed app's catalog exactly.
//
//   node supabase/generate_seed.mjs > supabase/migrations/004_seed_catalog.sql
//
// Price mapping note: the Flutter model stores `price` (selling) +
// `compareAtPrice` (higher struck-through). The DB normalizes to
// `price` (regular) + `sale_price` (<= price). So when discounted:
//   db.price = compareAtPrice   (regular)
//   db.sale_price = price       (sale)

import { writeFileSync } from 'node:fs';

const categories = [
  { slug: 'veg-spices',     name: 'Veg Spices',     description: '100% vegetarian spice blends formulated for a variety of dishes.', sort: 1 },
  { slug: 'pure-spices',    name: 'Pure Spices',    description: 'Single-ingredient ground spices and dried herbs, naturally pure.', sort: 2 },
  { slug: 'non-veg-spices', name: 'Non-Veg Spices', description: 'Signature masala blends crafted for chicken, mutton and fish.', sort: 3 },
  { slug: 'other-spices',   name: 'Other Spices',   description: 'Street-food favourites and specialty blends.', sort: 4 },
];

const groups = [
  { categoryId: 'veg-spices', categoryName: 'Veg Spices', isVeg: true, basePrice: 95, names: [
    'Chole Masala','Fried Rice Masala','Kitchen King Masala','Noodles Masala','Paneer Matar Masala',
    'Paneer Tikka Masala','Sabji Masala','Sambhar Powder','Shahi Malai Paneer Masala','Veg Manchuria Masala',
  ]},
  { categoryId: 'pure-spices', categoryName: 'Pure Spices', isVeg: true, basePrice: 70, names: [
    'Amchur Powder','Black Pepper Powder','Coriander Leaf','Curry Leaf','Garam Masala','Garlic Powder',
    'Ginger Powder','Green Capsicum Flakes','Green Chilli Flakes','Imli Powder','Jeera Powder',
    'Kasuri Methi Leaves','Lemon Powder','Mint Leaf','Moringa Leaf','Onion Powder','Oregano Leaves',
    'Paprika Powder','Parsley Leaves',
  ]},
  { categoryId: 'non-veg-spices', categoryName: 'Non-Veg Spices', isVeg: false, basePrice: 110, names: [
    'Biryani Masala','Chicken 65 Masala','Chicken Biryani Masala','Chicken Khorma Masala','Chicken Manchurian Masala',
    'Chicken Masala','Chicken Tikka Masala','Fish Masala','Karahi Ghost Masala','Mutton BBQ Masala',
    'Mutton Khorma Masala','Mutton Masala','Nihari Potli Masala','Shahi Malai Chicken Masala',
    'Shahi Malai Mutton Masala','Tandoori Masala and BBQ','Chapli Kabab Masala',
  ]},
  { categoryId: 'other-spices', categoryName: 'Other Spices', isVeg: true, basePrice: 90, names: [
    'Pani Puri Masala','Pav Bhaji Masala',
  ]},
];

const q = (s) => s.replace(/'/g, "''"); // SQL-escape single quotes

let out = `-- ============================================================================
-- NN Foods & Spices — 004_seed_catalog.sql  (GENERATED — do not edit by hand)
-- Regenerate with:  node supabase/generate_seed.mjs > supabase/migrations/004_seed_catalog.sql
--
-- The real published NN Food & Spices catalog: 4 categories, 48 products.
-- Seeded with currency 'INR' and empty image_url to preserve the exact
-- current appearance of the deployed mobile app (empty image_url renders the
-- app's branded placeholder tile). Idempotent via ON CONFLICT (slug).
-- ============================================================================

`;

for (const c of categories) {
  out += `insert into public.categories (slug, name, description, sort_order, is_active)
values ('${q(c.slug)}', '${q(c.name)}', '${q(c.description)}', ${c.sort}, true)
on conflict (slug) do update set
  name = excluded.name, description = excluded.description,
  sort_order = excluded.sort_order, is_active = excluded.is_active;\n\n`;
}

for (const g of groups) {
  g.names.forEach((name, i) => {
    const slug = `${g.categoryId}-${name.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`;
    const jitter = (i * 7) % 40;
    const sellingPrice = g.basePrice + jitter;          // Flutter Product.price
    const hasDiscount = i % 4 === 0;
    const regular = hasDiscount ? Math.round(sellingPrice * 1.2) : sellingPrice; // db price
    const sale = hasDiscount ? sellingPrice : null;      // db sale_price
    const rating = (4.2 + (i % 6) * 0.1).toFixed(1);
    const reviewCount = 8 + i * 3;
    const isFeatured = i % 5 === 0;
    const sku = slug.toUpperCase();
    const shortDesc = `100% Naturally Pure ${name}`;
    const desc = `${name} by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.`;

    out += `insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = '${q(g.categoryId)}'),
  '${q(slug)}', '${q(name)}', '${q(desc)}', '${q(shortDesc)}', '${q(sku)}',
  ${regular}, ${sale === null ? 'null' : sale}, 'INR',
  ${g.isVeg}, true, ${isFeatured}, 'in_stock', ${rating}, ${reviewCount}, ${i}
)
on conflict (slug) do nothing;\n\n`;
  });
}

writeFileSync(new URL('./migrations/004_seed_catalog.sql', import.meta.url), out);
process.stdout.write(`Wrote 004_seed_catalog.sql (${categories.length} categories, ${groups.reduce((n, g) => n + g.names.length, 0)} products)\n`);
