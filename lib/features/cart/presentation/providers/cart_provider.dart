import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/hive_service.dart';
import '../../../products/domain/product.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../domain/cart_item.dart';

String _cartKey(String productId, String packSize) => '$productId::$packSize';

class CartLine {
  const CartLine({required this.productId, required this.packSize, required this.quantity});
  final String productId;
  final String packSize;
  final int quantity;
}

/// Persists {productId::packSize -> quantity} in Hive. Product data itself
/// is looked up live from [productRepositoryProvider], so the cart never
/// goes stale relative to price/availability changes.
class CartNotifier extends StateNotifier<List<CartLine>> {
  CartNotifier() : super(_readFromBox());

  Box<int> get _box => Hive.box<int>(HiveBoxes.cart);

  static List<CartLine> _readFromBox() {
    final box = Hive.box<int>(HiveBoxes.cart);
    return box.keys.map((key) {
      final parts = (key as String).split('::');
      return CartLine(productId: parts[0], packSize: parts[1], quantity: box.get(key) ?? 0);
    }).where((l) => l.quantity > 0).toList();
  }

  void _persist() {
    state = _readFromBox();
  }

  Future<void> addToCart(Product product, {String? packSize, int quantity = 1}) async {
    final size = packSize ?? product.packSizes.first;
    final key = _cartKey(product.id, size);
    final current = _box.get(key) ?? 0;
    await _box.put(key, current + quantity);
    _persist();
  }

  Future<void> updateQuantity(String productId, String packSize, int quantity) async {
    final key = _cartKey(productId, packSize);
    if (quantity <= 0) {
      await _box.delete(key);
    } else {
      await _box.put(key, quantity);
    }
    _persist();
  }

  Future<void> removeItem(String productId, String packSize) async {
    await _box.delete(_cartKey(productId, packSize));
    _persist();
  }

  Future<void> clear() async {
    await _box.clear();
    _persist();
  }
}

final cartNotifierProvider = StateNotifierProvider<CartNotifier, List<CartLine>>((ref) {
  return CartNotifier();
});

final cartItemCountProvider = Provider<int>((ref) {
  final lines = ref.watch(cartNotifierProvider);
  return lines.fold(0, (sum, l) => sum + l.quantity);
});

/// Joins persisted cart lines with live product data for display.
final cartItemsProvider = FutureProvider<List<CartItem>>((ref) async {
  final lines = ref.watch(cartNotifierProvider);
  final repo = ref.watch(productRepositoryProvider);
  final items = <CartItem>[];
  for (final line in lines) {
    final result = await repo.getProductById(line.productId);
    result.when(
      success: (product) => items.add(
        CartItem(product: product, quantity: line.quantity, packSize: line.packSize),
      ),
      failure: (_) {},
    );
  }
  return items;
});

final cartSubtotalProvider = Provider<double>((ref) {
  final itemsAsync = ref.watch(cartItemsProvider);
  return itemsAsync.valueOrNull?.fold<double>(0, (sum, i) => sum + i.lineTotal) ?? 0;
});

class Coupon {
  const Coupon(this.code, this.discountPercent, this.minSubtotal);
  final String code;
  final int discountPercent;
  final double minSubtotal;
}

const availableCoupons = [
  Coupon('WELCOME10', 10, 0),
  Coupon('SPICE20', 20, 500),
];

final appliedCouponProvider = StateProvider<Coupon?>((ref) => null);

final cartDiscountProvider = Provider<double>((ref) {
  final coupon = ref.watch(appliedCouponProvider);
  final subtotal = ref.watch(cartSubtotalProvider);
  if (coupon == null || subtotal < coupon.minSubtotal) return 0;
  return subtotal * coupon.discountPercent / 100;
});

const _shippingFlatRate = 49.0;
const _freeShippingThreshold = 999.0;

final cartShippingProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  if (subtotal == 0) return 0;
  return subtotal >= _freeShippingThreshold ? 0 : _shippingFlatRate;
});

final cartTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final discount = ref.watch(cartDiscountProvider);
  final shipping = ref.watch(cartShippingProvider);
  return (subtotal - discount + shipping).clamp(0, double.infinity);
});
