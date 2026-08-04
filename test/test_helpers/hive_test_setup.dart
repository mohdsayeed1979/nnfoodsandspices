import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:nn_food_spices/core/storage/hive_service.dart';

/// Initializes Hive against a temp directory (no platform channels needed)
/// so widget/unit tests can exercise cart/wishlist/address providers
/// without the real `path_provider`-backed [HiveService.init].
Future<Directory> initTestHive() async {
  final dir = await Directory.systemTemp.createTemp('nn_food_spices_test_');
  Hive.init(dir.path);
  await Future.wait([
    Hive.openBox<int>(HiveBoxes.cart),
    Hive.openBox<bool>(HiveBoxes.wishlist),
    Hive.openBox<String>(HiveBoxes.recentSearches),
    Hive.openBox<Map>(HiveBoxes.addresses),
    Hive.openBox<Map>(HiveBoxes.orders),
    Hive.openBox<Map>(HiveBoxes.authUsers),
  ]);
  return dir;
}

Future<void> disposeTestHive(Directory dir) async {
  await Hive.deleteFromDisk();
  if (dir.existsSync()) {
    await dir.delete(recursive: true);
  }
}
