import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(wishlistProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: productsAsync.when(
        loading: () => const ProductGridShimmer(itemCount: 4),
        error: (e, _) => const Center(child: Text('Could not load wishlist')),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Your wishlist is empty'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.products),
                    child: const Text('Browse Products'),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.66,
            ),
            itemCount: products.length,
            itemBuilder: (context, i) => ProductCard(product: products[i]),
          );
        },
      ),
    );
  }
}
