import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../domain/cart_item.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(cartItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          itemsAsync.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox()
                : TextButton(
                    onPressed: () => ref.read(cartNotifierProvider.notifier).clear(),
                    child: const Text('Clear'),
                  ),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const ShimmerBox(height: 100),
        ),
        error: (e, _) => const Center(child: Text('Could not load your cart')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Your cart is empty'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.products),
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _CartItemTile(item: items[i]),
          );
        },
      ),
      bottomNavigationBar: itemsAsync.maybeWhen(
        data: (items) => items.isEmpty ? null : const _CartSummaryBar(),
        orElse: () => null,
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 76,
              height: 76,
              child: ProductImage(
                imageUrl: item.product.imageUrl,
                name: item.product.name,
                categoryName: item.product.categoryId,
                fit: BoxFit.contain,
                background: Theme.of(context).cardColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(
                  '${item.packSize} · ${AppConstants.currencySymbol}${item.unitPrice.toStringAsFixed(0)} each',
                  style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${AppConstants.currencySymbol}${item.lineTotal.toStringAsFixed(0)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
                      ),
                    ),
                    Row(
                      children: [
                        _qtyButton(
                          Icons.remove_rounded,
                          () => ref.read(cartNotifierProvider.notifier).updateQuantity(item.product.id, item.packSize, item.quantity - 1),
                        ),
                        SizedBox(width: 28, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
                        _qtyButton(
                          Icons.add_rounded,
                          () => ref.read(cartNotifierProvider.notifier).updateQuantity(item.product.id, item.packSize, item.quantity + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
            onPressed: () => ref.read(cartNotifierProvider.notifier).removeItem(item.product.id, item.packSize),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _CartSummaryBar extends ConsumerStatefulWidget {
  const _CartSummaryBar();

  @override
  ConsumerState<_CartSummaryBar> createState() => _CartSummaryBarState();
}

class _CartSummaryBarState extends ConsumerState<_CartSummaryBar> {
  final _couponController = TextEditingController();
  String? _couponError;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = ref.watch(cartSubtotalProvider);
    final discount = ref.watch(cartDiscountProvider);
    final shipping = ref.watch(cartShippingProvider);
    final total = ref.watch(cartTotalProvider);
    final coupon = ref.watch(appliedCouponProvider);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (coupon == null)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Coupon code (try WELCOME10)',
                        errorText: _couponError,
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      final code = _couponController.text.trim().toUpperCase();
                      final match = availableCoupons.where((c) => c.code == code);
                      if (match.isEmpty) {
                        setState(() => _couponError = 'Invalid coupon code');
                        return;
                      }
                      if (subtotal < match.first.minSubtotal) {
                        setState(() => _couponError = 'Minimum order ${AppConstants.currencySymbol}${match.first.minSubtotal.toStringAsFixed(0)} required');
                        return;
                      }
                      ref.read(appliedCouponProvider.notifier).state = match.first;
                      setState(() => _couponError = null);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(Icons.local_offer_rounded, size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: 6),
                  Text('${coupon.code} applied (-${coupon.discountPercent}%)', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 12.5)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => ref.read(appliedCouponProvider.notifier).state = null,
                    child: const Text('Remove'),
                  ),
                ],
              ),
            const Divider(height: 20),
            _summaryRow('Subtotal', subtotal),
            if (discount > 0) _summaryRow('Discount', -discount, color: AppColors.primaryGreen),
            _summaryRow('Shipping', shipping, isFree: shipping == 0),
            const Divider(height: 20),
            _summaryRow('Total', total, bold: true),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.checkout),
                child: const Text('Proceed to Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false, bool isFree = false, Color? color}) {
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
