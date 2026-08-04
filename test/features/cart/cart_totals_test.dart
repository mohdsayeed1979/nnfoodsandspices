import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nn_food_spices/features/cart/domain/cart_item.dart';
import 'package:nn_food_spices/features/cart/presentation/providers/cart_provider.dart';
import 'package:nn_food_spices/features/products/domain/product.dart';

Product _product(String id, double price) => Product(
      id: id,
      name: 'Test $id',
      slug: id,
      categoryId: 'pure-spices',
      categoryName: 'Pure Spices',
      description: 'desc',
      shortDescription: 'short',
      price: price,
      imageUrl: '',
      sku: id.toUpperCase(),
    );

void main() {
  group('Cart totals', () {
    late ProviderContainer container;

    ProviderContainer buildContainer(List<CartItem> items) {
      return ProviderContainer(
        overrides: [
          cartItemsProvider.overrideWith((ref) async => items),
        ],
      );
    }

    tearDown(() => container.dispose());

    test('subtotal sums line totals across items', () async {
      container = buildContainer([
        CartItem(product: _product('a', 100), quantity: 2, packSize: '100g'),
        CartItem(product: _product('b', 50), quantity: 3, packSize: '250g'),
      ]);
      await container.read(cartItemsProvider.future);
      expect(container.read(cartSubtotalProvider), 350); // 100*2 + 50*3
    });

    test('shipping is free at or above the free-shipping threshold', () async {
      container = buildContainer([CartItem(product: _product('a', 1000), quantity: 1, packSize: '1kg')]);
      await container.read(cartItemsProvider.future);
      expect(container.read(cartShippingProvider), 0);
    });

    test('shipping is flat-rate below the free-shipping threshold', () async {
      container = buildContainer([CartItem(product: _product('a', 200), quantity: 1, packSize: '100g')]);
      await container.read(cartItemsProvider.future);
      expect(container.read(cartShippingProvider), 49);
    });

    test('coupon discount only applies once minimum subtotal is met', () async {
      container = buildContainer([CartItem(product: _product('a', 200), quantity: 1, packSize: '100g')]);
      await container.read(cartItemsProvider.future);
      container.read(appliedCouponProvider.notifier).state = availableCoupons.firstWhere((c) => c.code == 'SPICE20');
      // Subtotal (200) is below SPICE20's minSubtotal (500), so no discount applies.
      expect(container.read(cartDiscountProvider), 0);
    });

    test('coupon discount applies once minimum subtotal is met', () async {
      container = buildContainer([CartItem(product: _product('a', 600), quantity: 1, packSize: '1kg')]);
      await container.read(cartItemsProvider.future);
      container.read(appliedCouponProvider.notifier).state = availableCoupons.firstWhere((c) => c.code == 'SPICE20');
      expect(container.read(cartDiscountProvider), 120); // 20% of 600
    });

    test('total combines subtotal, discount and shipping', () async {
      container = buildContainer([CartItem(product: _product('a', 200), quantity: 1, packSize: '100g')]);
      await container.read(cartItemsProvider.future);
      container.read(appliedCouponProvider.notifier).state = availableCoupons.firstWhere((c) => c.code == 'WELCOME10');
      // subtotal 200, discount 10% = 20, shipping 49 (below free threshold) => 229
      expect(container.read(cartTotalProvider), 229);
    });
  });
}
