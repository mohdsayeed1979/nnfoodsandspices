import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../checkout/presentation/providers/address_provider.dart';
import '../../../checkout/presentation/widgets/add_address_sheet.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => const AddAddressSheet(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Address'),
      ),
      body: addresses.isEmpty
          ? const Center(child: Text('No saved addresses yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final a = addresses[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: a.isDefault ? Border.all(color: AppColors.primaryGreen, width: 1.4) : null,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(a.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                if (a.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('DEFAULT', style: TextStyle(fontSize: 9, color: AppColors.primaryGreen, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(a.formatted, style: const TextStyle(fontSize: 12.5)),
                            Text(a.phone, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'default') ref.read(addressNotifierProvider.notifier).setDefault(a.id);
                          if (value == 'delete') ref.read(addressNotifierProvider.notifier).remove(a.id);
                        },
                        itemBuilder: (context) => [
                          if (!a.isDefault) const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
