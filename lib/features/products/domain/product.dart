import 'package:freezed_annotation/freezed_annotation.dart';

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

  bool get isInStock => availability == ProductAvailability.inStock;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}
