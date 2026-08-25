import 'package:flutter_test/flutter_test.dart';
import 'package:nn_food_spices/features/cart/domain/cart_item.dart';
import 'package:nn_food_spices/features/checkout/data/whatsapp_order_service.dart';
import 'package:nn_food_spices/features/checkout/domain/address.dart';
import 'package:nn_food_spices/features/checkout/domain/payment_method.dart';
import 'package:nn_food_spices/features/products/domain/pack_price.dart';
import 'package:nn_food_spices/features/products/domain/product.dart';

Product _product(String name, double base) => Product(
      id: name,
      name: name,
      slug: name,
      categoryId: 'pure-spices',
      categoryName: 'Pure Spices',
      description: '',
      shortDescription: '',
      price: base,
      imageUrl: '',
      sku: name,
      packPricing: PackPrice.defaultsFor(base),
    );

void main() {
  const service = WhatsAppOrderService();

  final address = const Address(
    id: 'a1',
    fullName: 'Mohammed Sayeed',
    phone: '+919701973386',
    line1: '12 Main Road',
    city: 'Shamshabad',
    state: 'Telangana',
    pincode: '501218',
  );

  test('order message carries the selected pack size, unit price and totals', () {
    final items = [
      CartItem(product: _product('Ginger Powder', 72), quantity: 2, packSize: '250g'),
      CartItem(product: _product('Chole Masala', 95), quantity: 1, packSize: '500g'),
    ];
    // Ginger 250g = round(72*2.3)=166 x2 = 332; Chole 500g = round(95*4.4)=418.
    final msg = service.buildMessage(
      items: items,
      address: address,
      paymentMethod: PaymentMethodType.cashOnDelivery,
      subtotal: 750,
      discount: 0,
      shipping: 49,
      total: 799,
    );

    expect(msg, contains('Mohammed Sayeed'));
    expect(msg, contains('+919701973386'));
    expect(msg, contains('Shamshabad'));
    expect(msg, contains('Ginger Powder'));
    expect(msg, contains('Pack Size: 250g'));
    expect(msg, contains('₹166 each'));
    expect(msg, contains('Total: ₹332'));
    expect(msg, contains('Pack Size: 500g'));
    expect(msg, contains('₹418'));
    expect(msg, contains('Shipping: ₹49'));
    expect(msg, contains('Total: ₹799'));
    expect(msg, contains('Cash on Delivery'));
    expect(msg, contains('Please confirm this order.'));
  });

  test('free shipping is labelled and discount line appears only when present', () {
    final items = [CartItem(product: _product('Amchur Powder', 70), quantity: 1, packSize: '100g')];
    final msg = service.buildMessage(
      items: items,
      address: address,
      paymentMethod: PaymentMethodType.cashOnDelivery,
      subtotal: 70,
      discount: 10,
      shipping: 0,
      total: 60,
    );
    expect(msg, contains('Shipping: FREE'));
    expect(msg, contains('Discount: -₹10'));
    expect(msg, contains('₹70 each'));
  });
}
