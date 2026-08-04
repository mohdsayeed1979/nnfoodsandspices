import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../checkout/domain/order.dart';
import '../../../checkout/presentation/providers/order_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No orders yet'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _OrderCard(order: orders[i]),
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  Color _statusColor(OrderStatus status) => switch (status) {
        OrderStatus.placed => AppColors.info,
        OrderStatus.confirmed => AppColors.primaryGreen,
        OrderStatus.shipped => AppColors.warning,
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled => AppColors.error,
      };

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
              Expanded(child: Text(order.id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5), overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _statusColor(order.status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(order.status.label, style: TextStyle(color: _statusColor(order.status), fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt), style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
          const Divider(height: 20),
          ...order.items.take(3).map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${i.product.name} x${i.quantity}', style: const TextStyle(fontSize: 12.5)),
              )),
          if (order.items.length > 3)
            Text('+${order.items.length - 3} more item(s)', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('${AppConstants.currencySymbol}${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryGreen, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
