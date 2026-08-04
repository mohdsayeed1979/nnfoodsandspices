import 'package:freezed_annotation/freezed_annotation.dart';

import '../../cart/domain/cart_item.dart';
import 'address.dart';
import 'payment_method.dart';

part 'order.freezed.dart';

enum OrderStatus { placed, confirmed, shipped, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.placed => 'Order Placed',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.shipped => 'Shipped',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };
}

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    required List<CartItem> items,
    required Address address,
    required PaymentMethodType paymentMethod,
    required double subtotal,
    required double discount,
    required double shipping,
    required double total,
    required DateTime createdAt,
    @Default(OrderStatus.placed) OrderStatus status,
  }) = _Order;
}
