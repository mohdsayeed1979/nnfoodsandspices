import '../domain/product.dart';
import '../domain/product_category.dart';

/// Seed catalog for the local data source.
///
/// Category and product names are the real catalog published on
/// https://nnfoodsandspices.com (Veg Spices / Pure Spices / Non-Veg Spices /
/// Other Spices, 35 products total). The live site is WordPress/WooCommerce
/// with no public API credentials available to this build, so pricing,
/// ratings and review counts below are representative placeholders — swap
/// [ProductRemoteDataSource] in once a WooCommerce REST API key is issued
/// and this seed data is no longer used.
class ProductSeedData {
  static const categories = <ProductCategory>[
    ProductCategory(
      id: 'veg-spices',
      name: 'Veg Spices',
      slug: 'veg-spices',
      description: '100% vegetarian spice blends formulated for a variety of dishes.',
      imageUrl: '',
      productCount: 10,
    ),
    ProductCategory(
      id: 'pure-spices',
      name: 'Pure Spices',
      slug: 'pure-spices',
      description: 'Single-ingredient ground spices and dried herbs, naturally pure.',
      imageUrl: '',
      productCount: 20,
    ),
    ProductCategory(
      id: 'non-veg-spices',
      name: 'Non-Veg Spices',
      slug: 'non-veg-spices',
      description: 'Signature masala blends crafted for chicken, mutton and fish.',
      imageUrl: '',
      productCount: 17,
    ),
    ProductCategory(
      id: 'other-spices',
      name: 'Other Spices',
      slug: 'other-spices',
      description: 'Street-food favourites and specialty blends.',
      imageUrl: '',
      productCount: 2,
    ),
  ];

  static final List<Product> products = [
    // ---- Veg Spices ----
    ..._buildGroup('veg-spices', 'Veg Spices', isVeg: true, basePrice: 95, names: const [
      'Chole Masala',
      'Fried Rice Masala',
      'Kitchen King Masala',
      'Noodles Masala',
      'Paneer Matar Masala',
      'Paneer Tikka Masala',
      'Sabji Masala',
      'Sambhar Powder',
      'Shahi Malai Paneer Masala',
      'Veg Manchuria Masala',
    ]),
    // ---- Pure Spices ----
    ..._buildGroup('pure-spices', 'Pure Spices', isVeg: true, basePrice: 70, names: const [
      'Amchur Powder',
      'Black Pepper Powder',
      'Coriander Leaf',
      'Curry Leaf',
      'Garam Masala',
      'Garlic Powder',
      'Ginger Powder',
      'Green Capsicum Flakes',
      'Green Chilli Flakes',
      'Imli Powder',
      'Jeera Powder',
      'Kasuri Methi Leaves',
      'Lemon Powder',
      'Mint Leaf',
      'Moringa Leaf',
      'Onion Powder',
      'Oregano Leaves',
      'Paprika Powder',
      'Parsley Leaves',
    ]),
    // ---- Non-Veg Spices ----
    ..._buildGroup('non-veg-spices', 'Non-Veg Spices', isVeg: false, basePrice: 110, names: const [
      'Biryani Masala',
      'Chicken 65 Masala',
      'Chicken Biryani Masala',
      'Chicken Khorma Masala',
      'Chicken Manchurian Masala',
      'Chicken Masala',
      'Chicken Tikka Masala',
      'Fish Masala',
      'Karahi Ghost Masala',
      'Mutton BBQ Masala',
      'Mutton Khorma Masala',
      'Mutton Masala',
      'Nihari Potli Masala',
      'Shahi Malai Chicken Masala',
      'Shahi Malai Mutton Masala',
      'Tandoori Masala and BBQ',
      'Chapli Kabab Masala',
    ]),
    // ---- Other Spices ----
    ..._buildGroup('other-spices', 'Other Spices', isVeg: true, basePrice: 90, names: const [
      'Pani Puri Masala',
      'Pav Bhaji Masala',
    ]),
  ];

  static List<Product> _buildGroup(
    String categoryId,
    String categoryName, {
    required bool isVeg,
    required double basePrice,
    required List<String> names,
  }) {
    return List.generate(names.length, (i) {
      final name = names[i];
      final id = '$categoryId-${name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-')}';
      // Deterministic pseudo-variety so the catalog doesn't look identical
      // row to row, without pretending to be real per-SKU pricing.
      final priceJitter = (i * 7) % 40;
      final price = basePrice + priceJitter;
      final hasDiscount = i % 4 == 0;
      return Product(
        id: id,
        name: name,
        slug: id,
        categoryId: categoryId,
        categoryName: categoryName,
        description:
            '$name by NN Food & Spices — 100% naturally pure, GMP & Halal certified, '
            'blended using a century-old family recipe with no artificial colours or fillers.',
        shortDescription: '100% Naturally Pure $name',
        price: price.toDouble(),
        compareAtPrice: hasDiscount ? (price * 1.2).roundToDouble() : null,
        imageUrl: '',
        rating: 4.2 + (i % 6) * 0.1,
        reviewCount: 8 + i * 3,
        isFeatured: i % 5 == 0,
        isLatest: i % 6 == 1,
        isVeg: isVeg,
        tags: [categoryName, if (hasDiscount) 'Offer'],
        sku: id.toUpperCase(),
      );
    });
  }
}
