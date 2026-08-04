import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/storage/hive_service.dart';
import '../../../cart/domain/cart_item.dart';
import '../../../products/domain/product.dart';
import '../../domain/address.dart';
import '../../domain/order.dart';
import '../../domain/payment_method.dart';

Map<String, dynamic> _orderToMap(Order order) => {
      'id': order.id,
      'items': order.items
          .map((i) => {
                'productId': i.product.id,
                'productName': i.product.name,
                'productImageUrl': i.product.imageUrl,
                'categoryId': i.product.categoryId,
                'price': i.product.price,
                'quantity': i.quantity,
                'packSize': i.packSize,
              })
          .toList(),
      'addressId': order.address.id,
      'addressFullName': order.address.fullName,
      'addressFormatted': order.address.formatted,
      'addressPhone': order.address.phone,
      'paymentMethod': order.paymentMethod.name,
      'subtotal': order.subtotal,
      'discount': order.discount,
      'shipping': order.shipping,
      'total': order.total,
      'createdAt': order.createdAt.toIso8601String(),
      'status': order.status.name,
    };

Order _orderFromMap(Map map) {
  final items = (map['items'] as List).map((raw) {
    final m = raw as Map;
    final product = Product(
      id: m['productId'] as String,
      name: m['productName'] as String,
      slug: m['productId'] as String,
      categoryId: m['categoryId'] as String,
      categoryName: '',
      description: '',
      shortDescription: '',
      price: (m['price'] as num).toDouble(),
      imageUrl: m['productImageUrl'] as String,
      sku: m['productId'] as String,
    );
    return CartItem(product: product, quantity: m['quantity'] as int, packSize: m['packSize'] as String);
  }).toList();

  return Order(
    id: map['id'] as String,
    items: items,
    address: Address(
      id: map['addressId'] as String,
      fullName: map['addressFullName'] as String,
      phone: map['addressPhone'] as String,
      line1: map['addressFormatted'] as String,
      city: '',
      state: '',
      pincode: '',
    ),
    paymentMethod: PaymentMethodType.values.byName(map['paymentMethod'] as String),
    subtotal: (map['subtotal'] as num).toDouble(),
    discount: (map['discount'] as num).toDouble(),
    shipping: (map['shipping'] as num).toDouble(),
    total: (map['total'] as num).toDouble(),
    createdAt: DateTime.parse(map['createdAt'] as String),
    status: OrderStatus.values.byName(map['status'] as String),
  );
}

class OrderNotifier extends StateNotifier<List<Order>> {
  OrderNotifier() : super(_readFromBox());

  Box<Map> get _box => Hive.box<Map>(HiveBoxes.orders);

  static List<Order> _readFromBox() {
    final box = Hive.box<Map>(HiveBoxes.orders);
    final orders = box.values.map(_orderFromMap).toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Future<Order> placeOrder({
    required List<CartItem> items,
    required Address address,
    required PaymentMethodType paymentMethod,
    required double subtotal,
    required double discount,
    required double shipping,
    required double total,
  }) async {
    final order = Order(
      id: 'NN${DateTime.now().millisecondsSinceEpoch}${const Uuid().v4().substring(0, 4).toUpperCase()}',
      items: items,
      address: address,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      discount: discount,
      shipping: shipping,
      total: total,
      createdAt: DateTime.now(),
    );
    await _box.put(order.id, _orderToMap(order));
    state = _readFromBox();
    return order;
  }
}

final orderNotifierProvider = StateNotifierProvider<OrderNotifier, List<Order>>((ref) {
  return OrderNotifier();
});
