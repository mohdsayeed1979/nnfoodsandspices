-- ============================================================================
-- NN Foods & Spices — 004_seed_catalog.sql  (GENERATED — do not edit by hand)
-- Regenerate with:  node supabase/generate_seed.mjs > supabase/migrations/004_seed_catalog.sql
--
-- The real published NN Food & Spices catalog: 4 categories, 48 products.
-- Seeded with currency 'INR' and empty image_url to preserve the exact
-- current appearance of the deployed mobile app (empty image_url renders the
-- app's branded placeholder tile). Idempotent via ON CONFLICT (slug).
-- ============================================================================

insert into public.categories (slug, name, description, sort_order, is_active)
values ('veg-spices', 'Veg Spices', '100% vegetarian spice blends formulated for a variety of dishes.', 1, true)
on conflict (slug) do update set
  name = excluded.name, description = excluded.description,
  sort_order = excluded.sort_order, is_active = excluded.is_active;

insert into public.categories (slug, name, description, sort_order, is_active)
values ('pure-spices', 'Pure Spices', 'Single-ingredient ground spices and dried herbs, naturally pure.', 2, true)
on conflict (slug) do update set
  name = excluded.name, description = excluded.description,
  sort_order = excluded.sort_order, is_active = excluded.is_active;

insert into public.categories (slug, name, description, sort_order, is_active)
values ('non-veg-spices', 'Non-Veg Spices', 'Signature masala blends crafted for chicken, mutton and fish.', 3, true)
on conflict (slug) do update set
  name = excluded.name, description = excluded.description,
  sort_order = excluded.sort_order, is_active = excluded.is_active;

insert into public.categories (slug, name, description, sort_order, is_active)
values ('other-spices', 'Other Spices', 'Street-food favourites and specialty blends.', 4, true)
on conflict (slug) do update set
  name = excluded.name, description = excluded.description,
  sort_order = excluded.sort_order, is_active = excluded.is_active;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-chole-masala', 'Chole Masala', 'Chole Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chole Masala', 'VEG-SPICES-CHOLE-MASALA',
  114, 95, 'INR',
  true, true, true, 'in_stock', 4.2, 8, 0
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-fried-rice-masala', 'Fried Rice Masala', 'Fried Rice Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Fried Rice Masala', 'VEG-SPICES-FRIED-RICE-MASALA',
  102, null, 'INR',
  true, true, false, 'in_stock', 4.3, 11, 1
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-kitchen-king-masala', 'Kitchen King Masala', 'Kitchen King Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Kitchen King Masala', 'VEG-SPICES-KITCHEN-KING-MASALA',
  109, null, 'INR',
  true, true, false, 'in_stock', 4.4, 14, 2
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-noodles-masala', 'Noodles Masala', 'Noodles Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Noodles Masala', 'VEG-SPICES-NOODLES-MASALA',
  116, null, 'INR',
  true, true, false, 'in_stock', 4.5, 17, 3
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-paneer-matar-masala', 'Paneer Matar Masala', 'Paneer Matar Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Paneer Matar Masala', 'VEG-SPICES-PANEER-MATAR-MASALA',
  148, 123, 'INR',
  true, true, false, 'in_stock', 4.6, 20, 4
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-paneer-tikka-masala', 'Paneer Tikka Masala', 'Paneer Tikka Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Paneer Tikka Masala', 'VEG-SPICES-PANEER-TIKKA-MASALA',
  130, null, 'INR',
  true, true, true, 'in_stock', 4.7, 23, 5
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-sabji-masala', 'Sabji Masala', 'Sabji Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Sabji Masala', 'VEG-SPICES-SABJI-MASALA',
  97, null, 'INR',
  true, true, false, 'in_stock', 4.2, 26, 6
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-sambhar-powder', 'Sambhar Powder', 'Sambhar Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Sambhar Powder', 'VEG-SPICES-SAMBHAR-POWDER',
  104, null, 'INR',
  true, true, false, 'in_stock', 4.3, 29, 7
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-shahi-malai-paneer-masala', 'Shahi Malai Paneer Masala', 'Shahi Malai Paneer Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Shahi Malai Paneer Masala', 'VEG-SPICES-SHAHI-MALAI-PANEER-MASALA',
  133, 111, 'INR',
  true, true, false, 'in_stock', 4.4, 32, 8
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'veg-spices'),
  'veg-spices-veg-manchuria-masala', 'Veg Manchuria Masala', 'Veg Manchuria Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Veg Manchuria Masala', 'VEG-SPICES-VEG-MANCHURIA-MASALA',
  118, null, 'INR',
  true, true, false, 'in_stock', 4.5, 35, 9
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-amchur-powder', 'Amchur Powder', 'Amchur Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Amchur Powder', 'PURE-SPICES-AMCHUR-POWDER',
  84, 70, 'INR',
  true, true, true, 'in_stock', 4.2, 8, 0
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-black-pepper-powder', 'Black Pepper Powder', 'Black Pepper Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Black Pepper Powder', 'PURE-SPICES-BLACK-PEPPER-POWDER',
  77, null, 'INR',
  true, true, false, 'in_stock', 4.3, 11, 1
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-coriander-leaf', 'Coriander Leaf', 'Coriander Leaf by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Coriander Leaf', 'PURE-SPICES-CORIANDER-LEAF',
  84, null, 'INR',
  true, true, false, 'in_stock', 4.4, 14, 2
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-curry-leaf', 'Curry Leaf', 'Curry Leaf by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Curry Leaf', 'PURE-SPICES-CURRY-LEAF',
  91, null, 'INR',
  true, true, false, 'in_stock', 4.5, 17, 3
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-garam-masala', 'Garam Masala', 'Garam Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Garam Masala', 'PURE-SPICES-GARAM-MASALA',
  118, 98, 'INR',
  true, true, false, 'in_stock', 4.6, 20, 4
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-garlic-powder', 'Garlic Powder', 'Garlic Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Garlic Powder', 'PURE-SPICES-GARLIC-POWDER',
  105, null, 'INR',
  true, true, true, 'in_stock', 4.7, 23, 5
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-ginger-powder', 'Ginger Powder', 'Ginger Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Ginger Powder', 'PURE-SPICES-GINGER-POWDER',
  72, null, 'INR',
  true, true, false, 'in_stock', 4.2, 26, 6
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-green-capsicum-flakes', 'Green Capsicum Flakes', 'Green Capsicum Flakes by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Green Capsicum Flakes', 'PURE-SPICES-GREEN-CAPSICUM-FLAKES',
  79, null, 'INR',
  true, true, false, 'in_stock', 4.3, 29, 7
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-green-chilli-flakes', 'Green Chilli Flakes', 'Green Chilli Flakes by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Green Chilli Flakes', 'PURE-SPICES-GREEN-CHILLI-FLAKES',
  103, 86, 'INR',
  true, true, false, 'in_stock', 4.4, 32, 8
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-imli-powder', 'Imli Powder', 'Imli Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Imli Powder', 'PURE-SPICES-IMLI-POWDER',
  93, null, 'INR',
  true, true, false, 'in_stock', 4.5, 35, 9
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-jeera-powder', 'Jeera Powder', 'Jeera Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Jeera Powder', 'PURE-SPICES-JEERA-POWDER',
  100, null, 'INR',
  true, true, true, 'in_stock', 4.6, 38, 10
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-kasuri-methi-leaves', 'Kasuri Methi Leaves', 'Kasuri Methi Leaves by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Kasuri Methi Leaves', 'PURE-SPICES-KASURI-METHI-LEAVES',
  107, null, 'INR',
  true, true, false, 'in_stock', 4.7, 41, 11
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-lemon-powder', 'Lemon Powder', 'Lemon Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Lemon Powder', 'PURE-SPICES-LEMON-POWDER',
  89, 74, 'INR',
  true, true, false, 'in_stock', 4.2, 44, 12
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-mint-leaf', 'Mint Leaf', 'Mint Leaf by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Mint Leaf', 'PURE-SPICES-MINT-LEAF',
  81, null, 'INR',
  true, true, false, 'in_stock', 4.3, 47, 13
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-moringa-leaf', 'Moringa Leaf', 'Moringa Leaf by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Moringa Leaf', 'PURE-SPICES-MORINGA-LEAF',
  88, null, 'INR',
  true, true, false, 'in_stock', 4.4, 50, 14
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-onion-powder', 'Onion Powder', 'Onion Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Onion Powder', 'PURE-SPICES-ONION-POWDER',
  95, null, 'INR',
  true, true, true, 'in_stock', 4.5, 53, 15
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-oregano-leaves', 'Oregano Leaves', 'Oregano Leaves by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Oregano Leaves', 'PURE-SPICES-OREGANO-LEAVES',
  122, 102, 'INR',
  true, true, false, 'in_stock', 4.6, 56, 16
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-paprika-powder', 'Paprika Powder', 'Paprika Powder by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Paprika Powder', 'PURE-SPICES-PAPRIKA-POWDER',
  109, null, 'INR',
  true, true, false, 'in_stock', 4.7, 59, 17
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'pure-spices'),
  'pure-spices-parsley-leaves', 'Parsley Leaves', 'Parsley Leaves by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Parsley Leaves', 'PURE-SPICES-PARSLEY-LEAVES',
  76, null, 'INR',
  true, true, false, 'in_stock', 4.2, 62, 18
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-biryani-masala', 'Biryani Masala', 'Biryani Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Biryani Masala', 'NON-VEG-SPICES-BIRYANI-MASALA',
  132, 110, 'INR',
  false, true, true, 'in_stock', 4.2, 8, 0
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-chicken-65-masala', 'Chicken 65 Masala', 'Chicken 65 Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chicken 65 Masala', 'NON-VEG-SPICES-CHICKEN-65-MASALA',
  117, null, 'INR',
  false, true, false, 'in_stock', 4.3, 11, 1
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-chicken-biryani-masala', 'Chicken Biryani Masala', 'Chicken Biryani Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chicken Biryani Masala', 'NON-VEG-SPICES-CHICKEN-BIRYANI-MASALA',
  124, null, 'INR',
  false, true, false, 'in_stock', 4.4, 14, 2
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-chicken-khorma-masala', 'Chicken Khorma Masala', 'Chicken Khorma Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chicken Khorma Masala', 'NON-VEG-SPICES-CHICKEN-KHORMA-MASALA',
  131, null, 'INR',
  false, true, false, 'in_stock', 4.5, 17, 3
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-chicken-manchurian-masala', 'Chicken Manchurian Masala', 'Chicken Manchurian Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chicken Manchurian Masala', 'NON-VEG-SPICES-CHICKEN-MANCHURIAN-MASALA',
  166, 138, 'INR',
  false, true, false, 'in_stock', 4.6, 20, 4
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-chicken-masala', 'Chicken Masala', 'Chicken Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chicken Masala', 'NON-VEG-SPICES-CHICKEN-MASALA',
  145, null, 'INR',
  false, true, true, 'in_stock', 4.7, 23, 5
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-chicken-tikka-masala', 'Chicken Tikka Masala', 'Chicken Tikka Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chicken Tikka Masala', 'NON-VEG-SPICES-CHICKEN-TIKKA-MASALA',
  112, null, 'INR',
  false, true, false, 'in_stock', 4.2, 26, 6
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-fish-masala', 'Fish Masala', 'Fish Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Fish Masala', 'NON-VEG-SPICES-FISH-MASALA',
  119, null, 'INR',
  false, true, false, 'in_stock', 4.3, 29, 7
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-karahi-ghost-masala', 'Karahi Ghost Masala', 'Karahi Ghost Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Karahi Ghost Masala', 'NON-VEG-SPICES-KARAHI-GHOST-MASALA',
  151, 126, 'INR',
  false, true, false, 'in_stock', 4.4, 32, 8
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-mutton-bbq-masala', 'Mutton BBQ Masala', 'Mutton BBQ Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Mutton BBQ Masala', 'NON-VEG-SPICES-MUTTON-BBQ-MASALA',
  133, null, 'INR',
  false, true, false, 'in_stock', 4.5, 35, 9
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-mutton-khorma-masala', 'Mutton Khorma Masala', 'Mutton Khorma Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Mutton Khorma Masala', 'NON-VEG-SPICES-MUTTON-KHORMA-MASALA',
  140, null, 'INR',
  false, true, true, 'in_stock', 4.6, 38, 10
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-mutton-masala', 'Mutton Masala', 'Mutton Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Mutton Masala', 'NON-VEG-SPICES-MUTTON-MASALA',
  147, null, 'INR',
  false, true, false, 'in_stock', 4.7, 41, 11
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-nihari-potli-masala', 'Nihari Potli Masala', 'Nihari Potli Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Nihari Potli Masala', 'NON-VEG-SPICES-NIHARI-POTLI-MASALA',
  137, 114, 'INR',
  false, true, false, 'in_stock', 4.2, 44, 12
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-shahi-malai-chicken-masala', 'Shahi Malai Chicken Masala', 'Shahi Malai Chicken Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Shahi Malai Chicken Masala', 'NON-VEG-SPICES-SHAHI-MALAI-CHICKEN-MASALA',
  121, null, 'INR',
  false, true, false, 'in_stock', 4.3, 47, 13
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-shahi-malai-mutton-masala', 'Shahi Malai Mutton Masala', 'Shahi Malai Mutton Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Shahi Malai Mutton Masala', 'NON-VEG-SPICES-SHAHI-MALAI-MUTTON-MASALA',
  128, null, 'INR',
  false, true, false, 'in_stock', 4.4, 50, 14
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-tandoori-masala-and-bbq', 'Tandoori Masala and BBQ', 'Tandoori Masala and BBQ by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Tandoori Masala and BBQ', 'NON-VEG-SPICES-TANDOORI-MASALA-AND-BBQ',
  135, null, 'INR',
  false, true, true, 'in_stock', 4.5, 53, 15
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'non-veg-spices'),
  'non-veg-spices-chapli-kabab-masala', 'Chapli Kabab Masala', 'Chapli Kabab Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Chapli Kabab Masala', 'NON-VEG-SPICES-CHAPLI-KABAB-MASALA',
  170, 142, 'INR',
  false, true, false, 'in_stock', 4.6, 56, 16
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'other-spices'),
  'other-spices-pani-puri-masala', 'Pani Puri Masala', 'Pani Puri Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Pani Puri Masala', 'OTHER-SPICES-PANI-PURI-MASALA',
  108, 90, 'INR',
  true, true, true, 'in_stock', 4.2, 8, 0
)
on conflict (slug) do nothing;

insert into public.products
  (category_id, slug, name, description, short_description, sku, price, sale_price, currency,
   is_veg, is_active, is_featured, stock_status, rating, review_count, sort_order)
values (
  (select id from public.categories where slug = 'other-spices'),
  'other-spices-pav-bhaji-masala', 'Pav Bhaji Masala', 'Pav Bhaji Masala by NN Food & Spices — 100% naturally pure, GMP & Halal certified, blended using a century-old family recipe with no artificial colours or fillers.', '100% Naturally Pure Pav Bhaji Masala', 'OTHER-SPICES-PAV-BHAJI-MASALA',
  97, null, 'INR',
  true, true, false, 'in_stock', 4.3, 11, 1
)
on conflict (slug) do nothing;

