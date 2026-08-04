import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_service.dart';
import '../../products/domain/product.dart';
import '../../products/presentation/providers/product_providers.dart';

class WishlistNotifier extends StateNotifier<Set<String>> {
  WishlistNotifier() : super(_readFromBox());

  Box<bool> get _box => Hive.box<bool>(HiveBoxes.wishlist);

  static Set<String> _readFromBox() {
    final box = Hive.box<bool>(HiveBoxes.wishlist);
    return box.keys.cast<String>().where((k) => box.get(k) == true).toSet();
  }

  Future<void> toggle(String productId) async {
    if (_box.get(productId) == true) {
      await _box.delete(productId);
    } else {
      await _box.put(productId, true);
    }
    state = _readFromBox();
  }

  bool contains(String productId) => state.contains(productId);
}

final wishlistNotifierProvider = StateNotifierProvider<WishlistNotifier, Set<String>>((ref) {
  return WishlistNotifier();
});

final wishlistProductsProvider = FutureProvider<List<Product>>((ref) async {
  final ids = ref.watch(wishlistNotifierProvider);
  final repo = ref.watch(productRepositoryProvider);
  final products = <Product>[];
  for (final id in ids) {
    final result = await repo.getProductById(id);
    result.when(success: products.add, failure: (_) {});
  }
  return products;
});
