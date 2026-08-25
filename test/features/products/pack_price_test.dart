import 'package:flutter_test/flutter_test.dart';
import 'package:nn_food_spices/features/products/domain/pack_price.dart';
import 'package:nn_food_spices/features/products/domain/product.dart';

Product _product(double price, {List<PackPrice> packPricing = const []}) => Product(
      id: 'x',
      name: 'Test',
      slug: 'x',
      categoryId: 'pure-spices',
      categoryName: 'Pure Spices',
      description: 'desc',
      shortDescription: 'short',
      price: price,
      compareAtPrice: null,
      imageUrl: '',
      sku: 'X',
      packPricing: packPricing,
    );

void main() {
  group('PackPrice.defaultsFor', () {
    test('builds the 4-size ladder from the base using standard multipliers', () {
      final ladder = PackPrice.defaultsFor(72);
      expect(ladder.map((p) => p.size).toList(), ['100g', '250g', '500g', '1kg']);
      expect(ladder.map((p) => p.price).toList(), [72, 166, 317, 576]);
    });
  });

  group('Product per-size pricing', () {
    test('priceForSize uses explicit DB pack pricing when present', () {
      final p = _product(72, packPricing: const [
        PackPrice(size: '100g', price: 72),
        PackPrice(size: '250g', price: 150), // admin-set, not the multiplier
        PackPrice(size: '1kg', price: 500),
      ]);
      expect(p.priceForSize('100g'), 72);
      expect(p.priceForSize('250g'), 150);
      expect(p.priceForSize('1kg'), 500);
    });

    test('priceForSize falls back to the multiplier ladder without DB pricing', () {
      final p = _product(72);
      expect(p.priceForSize('100g'), 72);
      expect(p.priceForSize('250g'), 166);
      expect(p.priceForSize('500g'), 317);
      expect(p.priceForSize('1kg'), 576);
    });

    test('priceForSize falls back to base price for an unknown size', () {
      final p = _product(72);
      expect(p.priceForSize('5kg'), 72);
      expect(p.priceForSize(null), 72);
    });

    test('compareAtForSize scales the discount consistently across sizes', () {
      final p = _product(72).copyWith(compareAtPrice: 90); // ~20% off at 100g
      // ratio at 1kg = 576/72 = 8, so compareAt = 90*8 = 720.
      expect(p.compareAtForSize('1kg'), 720);
      // Discount percent stays constant regardless of size.
      expect(p.discountPercent, 20);
    });

    test('compareAtForSize is null when the product is not discounted', () {
      expect(_product(72).compareAtForSize('1kg'), isNull);
    });
  });
}
