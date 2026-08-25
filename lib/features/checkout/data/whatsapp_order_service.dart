import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../cart/domain/cart_item.dart';
import '../domain/address.dart';
import '../domain/payment_method.dart';

/// Builds and hands off a customer order to the business owner over WhatsApp.
///
/// This is the interim order channel until a real order/payment backend
/// exists: pressing "Place Order" opens WhatsApp pre-filled with the order.
/// The order is only truly received once the customer sends that message —
/// the app never fabricates an "order confirmed" state on its own.
///
/// The destination is the single configured business number
/// [AppConstants.whatsappNumber] — no number is hardcoded at the call site.
class WhatsAppOrderService {
  const WhatsAppOrderService();

  /// Formats the full order as a readable WhatsApp message.
  String buildMessage({
    required List<CartItem> items,
    required Address address,
    required PaymentMethodType paymentMethod,
    required double subtotal,
    required double discount,
    required double shipping,
    required double total,
  }) {
    final c = AppConstants.currencySymbol;
    final b = StringBuffer()
      ..writeln('*NN Foods & Spices — New Order*')
      ..writeln()
      ..writeln('*Customer:*')
      ..writeln(address.fullName)
      ..writeln()
      ..writeln('*Phone:*')
      ..writeln(address.phone)
      ..writeln()
      ..writeln('*Delivery Address:*')
      ..writeln(address.formatted)
      ..writeln()
      ..writeln('--------------------------------')
      ..writeln()
      ..writeln('*Order Items:*')
      ..writeln();

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final unit = item.unitPrice;
      b
        ..writeln('${i + 1}. ${item.product.name}')
        ..writeln('   Pack Size: ${item.packSize}')
        ..writeln('   Qty: ${item.quantity}')
        ..writeln('   Price: $c${unit.toStringAsFixed(0)} each')
        ..writeln('   Total: $c${item.lineTotal.toStringAsFixed(0)}')
        ..writeln();
    }

    b
      ..writeln('--------------------------------')
      ..writeln()
      ..writeln('Subtotal: $c${subtotal.toStringAsFixed(0)}');
    if (discount > 0) b.writeln('Discount: -$c${discount.toStringAsFixed(0)}');
    b
      ..writeln('Shipping: ${shipping == 0 ? 'FREE' : '$c${shipping.toStringAsFixed(0)}'}')
      ..writeln('*Total: $c${total.toStringAsFixed(0)}*')
      ..writeln()
      ..writeln('--------------------------------')
      ..writeln()
      ..writeln('*Payment Method:*')
      ..writeln(paymentMethod.label)
      ..writeln()
      ..writeln('Please confirm this order.');

    return b.toString();
  }

  /// Opens WhatsApp (app first, then browser fallback) with [message]
  /// pre-filled to the business number. Returns true only if a handoff
  /// target actually launched — the caller must not treat the order as
  /// placed when this returns false.
  Future<bool> sendOrder(String message) async {
    final encoded = Uri.encodeComponent(message);
    final number = AppConstants.whatsappNumber;

    // 1) Native WhatsApp app via the wa.me deep link.
    final appUri = Uri.parse('https://wa.me/$number?text=$encoded');
    if (await _tryLaunch(appUri, LaunchMode.externalApplication)) return true;

    // 2) Browser / WhatsApp Web fallback.
    final webUri = Uri.parse('https://api.whatsapp.com/send?phone=$number&text=$encoded');
    if (await _tryLaunch(webUri, LaunchMode.externalApplication)) return true;
    if (await _tryLaunch(webUri, LaunchMode.platformDefault)) return true;

    return false;
  }

  Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
    try {
      return await launchUrl(uri, mode: mode);
    } catch (_) {
      return false;
    }
  }
}
