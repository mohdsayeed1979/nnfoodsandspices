import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../core/widgets/whatsapp_fab.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../widgets/category_quick_list.dart';
import '../widgets/hero_banner_slider.dart';
import '../widgets/home_sections.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredProductsProvider);
    final latest = ref.watch(latestProductsProvider);

    return Scaffold(
      floatingActionButton: const WhatsAppFab(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featuredProductsProvider);
          ref.invalidate(latestProductsProvider);
          ref.invalidate(categoriesProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              titleSpacing: 16,
              title: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(5),
                    child: Image.asset('assets/splash/splash_logo.png'),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(AppConstants.appName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.favorite_border_rounded),
                  onPressed: () => context.push(AppRoutes.wishlist),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: _SearchBarField(onTap: () => context.push(AppRoutes.search)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            const SliverToBoxAdapter(child: HeroBannerSlider()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const SliverToBoxAdapter(child: CategoryQuickList()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: SectionHeader(title: 'Featured Products', onViewAll: () => context.push(AppRoutes.products)),
            ),
            SliverToBoxAdapter(child: _ProductRow(asyncProducts: featured)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: SectionHeader(title: 'Latest Arrivals', onViewAll: () => context.push(AppRoutes.products)),
            ),
            SliverToBoxAdapter(child: _ProductRow(asyncProducts: latest)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(child: WhyChooseUsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(child: RecipeIdeasSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(child: TestimonialsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(child: SocialAndNewsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(child: NewsletterSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            const SliverToBoxAdapter(child: HomeContactSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _SearchBarField extends StatelessWidget {
  const _SearchBarField({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search for spices, masalas...',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13.5),
                ),
              ),
              Icon(Icons.mic_none_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.asyncProducts});
  final AsyncValue asyncProducts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 248,
      child: asyncProducts.when(
        loading: () => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => const ShimmerBox(width: 165, height: 248, borderRadius: 16),
        ),
        error: (e, _) => Center(child: Text('Could not load products', style: TextStyle(color: Theme.of(context).colorScheme.error))),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products yet'));
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(width: 165, child: ProductCard(product: products[i])),
          );
        },
      ),
    );
  }
}
