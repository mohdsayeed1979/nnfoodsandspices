import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/providers/cart_provider.dart';
import '../../features/products/domain/product.dart';
import '../../features/wishlist/presentation/wishlist_provider.dart';
import '../constants/app_constants.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import 'product_image.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, this.listMode = false});

  final Product product;
  final bool listMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWishlisted = ref.watch(wishlistNotifierProvider).contains(product.id);
    final heroTag = 'product-image-${product.id}';

    final card = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: listMode ? _buildListLayout(context, ref, isWishlisted, heroTag) : _buildGridLayout(context, ref, isWishlisted, heroTag),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push(AppRoutes.productDetailPath(product.id)),
      child: card,
    );
  }

  Widget _buildGridLayout(BuildContext context, WidgetRef ref, bool isWishlisted, String heroTag) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ProductImage(
                    imageUrl: product.imageUrl,
                    name: product.name,
                    categoryName: product.categoryId,
                    heroTag: heroTag,
                  ),
                ),
                if (product.hasDiscount) _discountBadge(),
                Positioned(top: 6, right: 6, child: _wishlistButton(ref, isWishlisted)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 7, 9, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
                ),
                const SizedBox(height: 3),
                _ratingRow(context),
                const SizedBox(height: 5),
                _priceAndAddRow(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListLayout(BuildContext context, WidgetRef ref, bool isWishlisted, String heroTag) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 132,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 132,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProductImage(
                      imageUrl: product.imageUrl,
                      name: product.name,
                      categoryName: product.categoryId,
                      heroTag: heroTag,
                    ),
                  ),
                  if (product.hasDiscount) _discountBadge(),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                        _wishlistButton(ref, isWishlisted),
                      ],
                    ),
                    _ratingRow(context),
                    _priceAndAddRow(context, ref),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _discountBadge() {
    return Positioned(
      top: 6,
      left: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${product.discountPercent}% OFF',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _wishlistButton(WidgetRef ref, bool isWishlisted) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => ref.read(wishlistNotifierProvider.notifier).toggle(product.id),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 16,
            color: isWishlisted ? AppColors.primaryOrange : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _ratingRow(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 12.5, color: AppColors.ratingStar),
        const SizedBox(width: 2),
        Text(product.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
        const SizedBox(width: 3),
        Text('(${product.reviewCount})', style: TextStyle(fontSize: 9.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
      ],
    );
  }

  Widget _priceAndAddRow(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${AppConstants.currencySymbol}${product.price.toStringAsFixed(0)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
                ),
              ),
              if (product.hasDiscount) ...[
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    '${AppConstants.currencySymbol}${product.compareAtPrice!.toStringAsFixed(0)}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      decoration: TextDecoration.lineThrough,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Material(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: product.isInStock
                ? () {
                    ref.read(cartNotifierProvider.notifier).addToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${product.name} added to cart'), duration: const Duration(seconds: 1)),
                    );
                  }
                : null,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.add_shopping_cart_rounded, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
