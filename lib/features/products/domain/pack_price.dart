import 'package:flutter/foundation.dart';

/// The customer-facing selling price for one pack size of a product.
///
/// This is the app-side mirror of the DB `products.pack_sizes` jsonb, which
/// stores an array of `{ "size": "250g", "price": 161 }` objects. The DB is
/// the single source of truth for per-size prices; [defaultsFor] is only a
/// fallback used for the bundled offline seed catalog (and for any legacy row
/// whose `pack_sizes` is still a plain string array with no prices).
@immutable
class PackPrice {
  const PackPrice({required this.size, required this.price});

  final String size;
  final double price;

  factory PackPrice.fromJson(Map<String, dynamic> json) => PackPrice(
        size: json['size'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {'size': size, 'price': price};

  /// Standard pack multipliers relative to the 100g base selling price.
  /// Bigger packs are cheaper per gram (a normal retail bulk discount).
  /// Used ONLY as a fallback when the DB has no explicit per-size prices —
  /// once an admin sets real prices they always win.
  static const Map<String, double> multipliers = {
    '100g': 1.0,
    '250g': 2.3,
    '500g': 4.4,
    '1kg': 8.0,
  };

  /// Builds the standard 4-size price ladder from a 100g base price.
  static List<PackPrice> defaultsFor(double base) => [
        for (final entry in multipliers.entries)
          PackPrice(size: entry.key, price: (base * entry.value).roundToDouble()),
      ];

  @override
  bool operator ==(Object other) =>
      other is PackPrice && other.size == size && other.price == price;

  @override
  int get hashCode => Object.hash(size, price);
}
