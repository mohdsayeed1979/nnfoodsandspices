import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../domain/payment_method.dart';
import '../../data/payment_service.dart';
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
            child: RadioGroup<PaymentMethodType>(
              groupValue: selectedPayment,
              onChanged: (v) => ref.read(_selectedPaymentMethodProvider.notifier).state = v!,
              child: Column(
                children: PaymentMethodType.values.map((type) {
                  final service = paymentServiceFor(type);
                  return RadioListTile<PaymentMethodType>(
                    value: type,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primaryGreen,
                    title: Text(type.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: service.isConfigured ? null : const Text('Requires setup — coming soon', style: TextStyle(fontSize: 11, color: AppColors.warning)),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Order Summary',
            child: itemsAsync.maybeWhen(
              data: (items) => Column(
                children: [
                  ...items.map((i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text('${i.product.name} x${i.quantity}', style: const TextStyle(fontSize: 12.5))),
                            Text('${AppConstants.currencySymbol}${i.lineTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
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
    if (items.isEmpty) return;
    setState(() => _placing = true);
    final address = ref.read(addressNotifierProvider).firstWhere((a) => a.id == _selectedAddressId);
    final orderId = 'pending';
    final paymentResult = await paymentServiceFor(paymentMethod).pay(amount: total, orderId: orderId);

    if (!paymentResult.isSuccess) {
      setState(() => _placing = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(paymentResult.failureMessage ?? 'Payment failed')),
        );
      }
      return;
    }

    final order = await ref.read(orderNotifierProvider.notifier).placeOrder(
          items: items.cast(),
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
