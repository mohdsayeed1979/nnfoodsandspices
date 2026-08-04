import 'package:freezed_annotation/freezed_annotation.dart';

import '../../products/domain/product.dart';

part 'cart_item.freezed.dart';

@freezed
abstract class CartItem with _$CartItem {
  const factory CartItem({
    required Product product,
    required int quantity,
    required String packSize,
  }) = _CartItem;

  const CartItem._();

  double get lineTotal => product.price * quantity;
}
