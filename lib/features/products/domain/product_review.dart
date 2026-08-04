import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_review.freezed.dart';
part 'product_review.g.dart';

@freezed
abstract class ProductReview with _$ProductReview {
  const factory ProductReview({
    required String id,
    required String productId,
    required String authorName,
    required double rating,
    required String comment,
    required DateTime createdAt,
    @Default(false) bool verifiedPurchase,
  }) = _ProductReview;

  factory ProductReview.fromJson(Map<String, dynamic> json) =>
      _$ProductReviewFromJson(json);
}
