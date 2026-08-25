import 'package:freezed_annotation/freezed_annotation.dart';

import 'pack_price.dart';

part 'product.freezed.dart';
part 'product.g.dart';

enum ProductAvailability { inStock, outOfStock, comingSoon }

@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required String slug,
    required String categoryId,
    required String categoryName,
    required String description,
    required String shortDescription,
    required double price,
    double? compareAtPrice,
    @Default('INR') String currency,
    required String imageUrl,
    @Default(<String>[]) List<String> galleryImages,
    @Default(<String>['100g', '250g', '500g', '1kg']) List<String> packSizes,
    // Per-size selling prices. Sourced from the DB `pack_sizes` jsonb (single
    // source of truth); the repositories build it explicitly. Serializable so
    // json_serializable can round-trip it (PackPrice has its own to/fromJson).
    @Default(<PackPrice>[]) List<PackPrice> packPricing,
    @Default(4.5) double rating,
    @Default(0) int reviewCount,
    @Default(ProductAvailability.inStock) ProductAvailability availability,
    @Default(false) bool isFeatured,
    @Default(false) bool isLatest,
    @Default(false) bool isVeg,
    @Default(<String>[]) List<String> tags,
    @Default(<String>[]) List<String> relatedProductIds,
    required String sku,
  }) = _Product;

  const Product._();

  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > price;

  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  /// The effective per-size price ladder: the DB-sourced [packPricing] when
  /// present, otherwise a multiplier-derived fallback built from [price] so
  /// the offline seed catalog and any un-migrated row still vary by size.
  List<PackPrice> get effectivePackPricing =>
      packPricing.isNotEmpty ? packPricing : PackPrice.defaultsFor(price);

  /// The selling price for [size]. Falls back to the base [price] for an
  /// unknown size (e.g. a legacy cart entry whose size was later removed).
  double priceForSize(String? size) {
    if (size == null) return price;
    for (final p in effectivePackPricing) {
      if (p.size == size) return p.price;
    }
    return price;
  }

  /// The struck-through original price for [size], scaled from the product's
  /// 100g discount so the discount % stays consistent across all sizes.
  /// Null when the product isn't discounted.
  double? compareAtForSize(String? size) {
    if (!hasDiscount || price == 0) return null;
    final ratio = priceForSize(size) / price;
    return (compareAtPrice! * ratio).roundToDouble();
  }

  bool get isInStock => availability == ProductAvailability.inStock;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}
