import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../cart/domain/cart_item.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../domain/payment_method.dart';
import '../../data/payment_service.dart';
import '../../data/whatsapp_order_service.dart';
import '../providers/address_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/add_address_sheet.dart';

final _selectedPaymentMethodProvider = StateProvider<PaymentMethodType>((ref) => PaymentMethodType.cashOnDelivery);

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _selectedAddressId;
  bool _placing = false;

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(addressNotifierProvider);
    final itemsAsync = ref.watch(cartItemsProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final discount = ref.watch(cartDiscountProvider);
    final shipping = ref.watch(cartShippingProvider);
    final total = ref.watch(cartTotalProvider);
    final selectedPayment = ref.watch(_selectedPaymentMethodProvider);

    _selectedAddressId ??= ref.read(defaultAddressProvider)?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Delivery Address',
            trailing: TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => const AddAddressSheet(),
              ).then((address) {
                if (address != null) setState(() => _selectedAddressId = address.id);
              }),
              child: const Text('+ Add New'),
            ),
            child: addresses.isEmpty
                ? const Padding(padding: EdgeInsets.all(8), child: Text('No saved addresses yet. Add one to continue.'))
                : RadioGroup<String>(
                    groupValue: _selectedAddressId,
                    onChanged: (v) => setState(() => _selectedAddressId = v),
                    child: Column(
                      children: addresses.map((a) {
                        return RadioListTile<String>(
                          value: a.id,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primaryGreen,
                          title: Text(a.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                          subtitle: Text('${a.formatted}\n${a.phone}', style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Shipping Method',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_shipping_outlined, color: AppColors.primaryGreen),
              title: Text(shipping == 0 ? 'Free Standard Shipping' : 'Standard Shipping'),
              subtitle: const Text('Delivered in 3-5 business days'),
              trailing: Text(shipping == 0 ? 'FREE' : '${AppConstants.currencySymbol}${shipping.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Payment Method',
            child: Column(
              children: PaymentMethodType.values.map((type) {
                final service = paymentServiceFor(type);
                final available = service.isConfigured; // only COD today
                return _PaymentOption(
                  type: type,
                  available: available,
                  selected: selectedPayment == type,
                  onTap: available
                      ? () => ref.read(_selectedPaymentMethodProvider.notifier).state = type
                      : null,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Order Summary',
            child: itemsAsync.maybeWhen(
              data: (items) => Column(
                children: [
                  ...items.map((i) => _OrderSummaryLine(item: i)),
                  const Divider(height: 20),
                  _row('Subtotal', subtotal),
                  if (discount > 0) _row('Discount', -discount, color: AppColors.primaryGreen),
                  _row('Shipping', shipping, isFree: shipping == 0),
                  const Divider(height: 20),
                  _row('Total', total, bold: true),
                ],
              ),
              orElse: () => const SizedBox(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedAddressId == null || _placing ? null : () => _placeOrder(context, itemsAsync.valueOrNull ?? [], subtotal, discount, shipping, total, selectedPayment),
              child: _placing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Place Order'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(
    BuildContext context,
    List items,
    double subtotal,
    double discount,
    double shipping,
    double total,
    PaymentMethodType paymentMethod,
  ) async {
    // Guard rails: non-empty cart, a chosen address, and a payment method
    // that is actually available (online gateways are still "coming soon").
    if (items.isEmpty) return;
    if (_selectedAddressId == null) {
      _snack('Please select a delivery address.');
      return;
    }
    if (!paymentServiceFor(paymentMethod).isConfigured) {
      _snack('${paymentMethod.label} is coming soon. Please choose Cash on Delivery.');
      return;
    }

    setState(() => _placing = true);
    final address = ref.read(addressNotifierProvider).firstWhere((a) => a.id == _selectedAddressId);
    final cartItems = items.cast<CartItem>();

    // Hand the order off to the business owner over WhatsApp. The order is
    // only "placed" once the customer actually sends that message — so we do
    // NOT clear the cart or show a confirmation unless the handoff launched.
    const service = WhatsAppOrderService();
    final message = service.buildMessage(
      items: cartItems,
      address: address,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      discount: discount,
      shipping: shipping,
      total: total,
    );
    final launched = await service.sendOrder(message);

    if (!launched) {
      setState(() => _placing = false);
      _snack('Could not open WhatsApp. Please install WhatsApp or contact us to place your order.');
      return;
    }

    // Record the order locally for the user's order history, then clear the
    // cart now that the details are safely in WhatsApp for the customer to send.
    final order = await ref.read(orderNotifierProvider.notifier).placeOrder(
          items: cartItems,
          address: address,
          paymentMethod: paymentMethod,
          subtotal: subtotal,
          discount: discount,
          shipping: shipping,
          total: total,
        );
    await ref.read(cartNotifierProvider.notifier).clear();
    ref.read(appliedCouponProvider.notifier).state = null;
    setState(() => _placing = false);
    if (context.mounted) context.go('/cart/checkout/success', extra: order.id);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _row(String label, double value, {bool bold = false, bool isFree = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(
            isFree ? 'FREE' : '${value < 0 ? '-' : ''}${AppConstants.currencySymbol}${value.abs().toStringAsFixed(0)}',
            style: TextStyle(fontSize: bold ? 17 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? (bold ? AppColors.primaryGreen : null)),
          ),
        ],
      ),
    );
  }
}

/// One payment method row. Title + subtitle are stacked in a flexible column
/// so long labels like "Razorpay (Cards / UPI / Netbanking)" wrap instead of
/// overlapping the "coming soon" note. Unavailable methods are shown but not
/// selectable.
class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.type,
    required this.available,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethodType type;
  final bool available;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: !available
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                    : (selected ? AppColors.primaryGreen : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: available ? onSurface : onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  if (!available)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'Coming soon',
                        style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single order-summary line: name (wraps), the "pack × qty" and
/// "unit × qty" breakdown, and the line total — laid out so nothing overlaps
/// on small screens.
class _OrderSummaryLine extends StatelessWidget {
  const _OrderSummaryLine({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final c = AppConstants.currencySymbol;
    final subtle = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(
                  '${item.packSize} × ${item.quantity}   ·   $c${item.unitPrice.toStringAsFixed(0)} × ${item.quantity}',
                  style: TextStyle(fontSize: 11.5, color: subtle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('$c${item.lineTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
