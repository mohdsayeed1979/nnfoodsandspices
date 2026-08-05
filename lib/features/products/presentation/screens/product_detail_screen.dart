import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../wishlist/presentation/wishlist_provider.dart';
import '../../domain/product.dart';
import '../providers/product_providers.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _selectedPackSize;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));

    return Scaffold(
      body: productAsync.when(
        loading: () => const _DetailShimmer(),
        error: (e, _) => Center(child: Text('Product not found', style: Theme.of(context).textTheme.titleMedium)),
        data: (product) => _buildContent(context, product),
      ),
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) => _buildAddToCartBar(context, product),
        orElse: () => null,
      ),
    );
  }

  Widget _buildContent(BuildContext context, Product product) {
    _selectedPackSize ??= product.packSizes.first;
    final isWishlisted = ref.watch(wishlistNotifierProvider).contains(product.id);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          actions: [
            IconButton(
              icon: Icon(isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isWishlisted ? AppColors.primaryOrange : null),
              onPressed: () => ref.read(wishlistNotifierProvider.notifier).toggle(product.id),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => Share.share('${product.name} — ${AppConstants.tagline}\n${AppConstants.websiteUrl}'),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: GestureDetector(
              onTap: () => _openImageZoom(context, product),
              child: ProductImage(
                imageUrl: product.imageUrl,
                name: product.name,
                categoryName: product.categoryId,
                heroTag: 'product-image-${product.id}',
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(product.categoryName, style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.circle, size: 10, color: product.isVeg ? AppColors.success : AppColors.error),
                  ],
                ),
                const SizedBox(height: 10),
                Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.ratingStar, size: 18),
                    const SizedBox(width: 4),
                    Text(product.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(' (${product.reviewCount} reviews)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                    const Spacer(),
                    Text(
                      product.isInStock ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(color: product.isInStock ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600, fontSize: 12.5),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${AppConstants.currencySymbol}${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primaryGreen),
                    ),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: 10),
                      Text(
                        '${AppConstants.currencySymbol}${product.compareAtPrice!.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 16, decoration: TextDecoration.lineThrough, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(width: 8),
                      Text('${product.discountPercent}% OFF', style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Pack Size', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: product.packSizes.map((size) {
                    final selected = size == _selectedPackSize;
                    return ChoiceChip(
                      label: Text(size),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedPackSize = size),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 8),
                _QuantityStepper(
                  quantity: _quantity,
                  onChanged: (q) => setState(() => _quantity = q),
                ),
                const SizedBox(height: 24),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                Text(product.description, style: const TextStyle(fontSize: 13.5, height: 1.5)),
                const SizedBox(height: 24),
                const Text('Specifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                _SpecTable(product: product),
                const SizedBox(height: 28),
                Text('Reviews', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _ReviewsList(productId: product.id),
                const SizedBox(height: 28),
                Text('Related Products', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _RelatedProducts(productId: product.id)),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  void _openImageZoom(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
          body: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(
              child: ProductImage(imageUrl: product.imageUrl, name: product.name, categoryName: product.categoryId),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddToCartBar(BuildContext context, Product product) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: product.isInStock
                    ? () {
                        ref.read(cartNotifierProvider.notifier).addToCart(
                              product,
                              packSize: _selectedPackSize,
                              quantity: _quantity,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${product.name} added to cart')),
                        );
                      }
                    : null,
                child: const Text('Add to Cart'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: product.isInStock
                    ? () {
                        ref.read(cartNotifierProvider.notifier).addToCart(
                              product,
                              packSize: _selectedPackSize,
                              quantity: _quantity,
                            );
                        context.go(AppRoutes.checkout);
                      }
                    : null,
                child: const Text('Buy Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepButton(icon: Icons.remove_rounded, onTap: quantity > 1 ? () => onChanged(quantity - 1) : null),
        Container(
          width: 44,
          alignment: Alignment.center,
          child: Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        _StepButton(icon: Icons.add_rounded, onTap: quantity < 20 ? () => onChanged(quantity + 1) : null),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? Colors.grey.shade200 : AppColors.primaryGreen.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: onTap == null ? Colors.grey : AppColors.primaryGreen),
        ),
      ),
    );
  }
}

class _SpecTable extends StatelessWidget {
  const _SpecTable({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final specs = {
      'SKU': product.sku,
      'Category': product.categoryName,
      'Type': product.isVeg ? 'Vegetarian' : 'Non-Vegetarian',
      'Available Sizes': product.packSizes.join(', '),
      'Shelf Life': '12 months from packaging',
      'Certification': 'GMP & Halal Certified',
    };
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: specs.entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                SizedBox(width: 120, child: Text(e.key, style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)))),
                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReviewsList extends ConsumerWidget {
  const _ReviewsList({required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsProvider(productId));
    return reviewsAsync.when(
      loading: () => const ShimmerBox(height: 80),
      error: (e, _) => const SizedBox(),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Text('No reviews yet. Be the first to review this product!', style: TextStyle(fontSize: 13, color: Colors.grey));
        }
        return Column(
          children: reviews.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                    child: Text(r.authorName.substring(0, 1), style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(r.authorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            if (r.verifiedPurchase) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, size: 14, color: AppColors.primaryGreen),
                            ],
                          ],
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < r.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 14,
                              color: AppColors.ratingStar,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(r.comment, style: const TextStyle(fontSize: 12.5, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RelatedProducts extends ConsumerWidget {
  const _RelatedProducts({required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedAsync = ref.watch(relatedProductsProvider(productId));
    return SizedBox(
      height: 220,
      child: relatedAsync.when(
        loading: () => const SizedBox(),
        error: (e, _) => const SizedBox(),
        data: (products) {
          if (products.isEmpty) return const SizedBox();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(width: 148, child: ProductCard(product: products[i])),
          );
        },
      ),
    );
  }
}

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        ShimmerBox(height: 300, borderRadius: 16),
        SizedBox(height: 20),
        ShimmerBox(height: 24, width: 200),
        SizedBox(height: 12),
        ShimmerBox(height: 18, width: 120),
        SizedBox(height: 20),
        ShimmerBox(height: 80),
      ],
    );
  }
}
