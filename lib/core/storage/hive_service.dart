import 'package:hive_flutter/hive_flutter.dart';

/// Boxes store plain primitives (no generated TypeAdapters needed) so the
/// storage layer stays dependency-free of codegen: cart/wishlist only ever
/// need product-id keys, quantities and timestamps.
abstract final class HiveBoxes {
  static const cart = 'cart_box';
  static const wishlist = 'wishlist_box';
  static const recentSearches = 'recent_searches_box';
  static const addresses = 'addresses_box';
  static const orders = 'orders_box';
  static const authUsers = 'auth_users_box';
}

class HiveService {
  HiveService._();

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<int>(HiveBoxes.cart),
      Hive.openBox<bool>(HiveBoxes.wishlist),
      Hive.openBox<String>(HiveBoxes.recentSearches),
      Hive.openBox<Map>(HiveBoxes.addresses),
      Hive.openBox<Map>(HiveBoxes.orders),
      Hive.openBox<Map>(HiveBoxes.authUsers),
    ]);
  }
}
