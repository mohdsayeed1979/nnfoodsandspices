import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../providers/product_providers.dart';
import '../widgets/filter_sort_sheet.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key, this.categoryId, this.categoryName});

  final String? categoryId;
  final String? categoryName;

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  bool _gridMode = true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.categoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(productListProvider.notifier).updateQuery(
              (q) => q.copyWith(categoryId: widget.categoryId),
            );
      });
    }
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) {
        ref.read(productListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final notifier = ref.read(productListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName ?? 'All Products'),
        actions: [
          IconButton(
            icon: Icon(_gridMode ? Icons.view_list_rounded : Icons.grid_view_rounded),
            tooltip: _gridMode ? 'List view' : 'Grid view',
            onPressed: () => setState(() => _gridMode = !_gridMode),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (_) => FilterSortSheet(notifier: notifier),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('Filter & Sort'),
                  ),
                ),
                const SizedBox(width: 10),
                _VegToggleChip(notifier: notifier),
              ],
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const ProductGridShimmer(itemCount: 8),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
                      const SizedBox(height: 8),
                      const Text('Could not load products'),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: notifier.load, child: const Text('Retry')),
                    ],
                  ),
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No products match your filters.'),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: notifier.load,
                  child: _gridMode
                      ? GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.62,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, i) => ProductCard(product: products[i]),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => ProductCard(product: products[i], listMode: true),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VegToggleChip extends ConsumerWidget {
  const _VegToggleChip({required this.notifier});
  final ProductListNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVeg = notifier.query.isVeg;
    return PopupMenuButton<bool?>(
      initialValue: isVeg,
      onSelected: (value) => notifier.updateQuery((q) => q.copyWith(isVeg: value, clearVeg: value == null)),
      itemBuilder: (context) => const [
        PopupMenuItem(value: null, child: Text('All')),
        PopupMenuItem(value: true, child: Text('Veg only')),
        PopupMenuItem(value: false, child: Text('Non-Veg only')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 10,
              color: isVeg == null ? Colors.grey : (isVeg ? AppColors.success : AppColors.error),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}
