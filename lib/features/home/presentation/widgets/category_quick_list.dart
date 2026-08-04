import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../products/presentation/providers/product_providers.dart';

const _categoryIcons = <String, IconData>{
  'veg-spices': Icons.eco_rounded,
  'pure-spices': Icons.grass_rounded,
  'non-veg-spices': Icons.set_meal_rounded,
  'other-spices': Icons.local_dining_rounded,
};

const _categoryColors = <String, Color>{
  'veg-spices': Color(0xFF7CB342),
  'pure-spices': Color(0xFFF9A825),
  'non-veg-spices': Color(0xFFE64A19),
  'other-spices': AppColors.primaryOrange,
};

class CategoryQuickList extends ConsumerWidget {
  const CategoryQuickList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Shop by Category', onViewAll: () => context.push(AppRoutes.categories)),
        SizedBox(
          height: 104,
          child: categoriesAsync.when(
            loading: () => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const ShimmerBox(width: 84, height: 104, borderRadius: 16),
            ),
            error: (e, _) => const SizedBox(),
            data: (categories) => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final c = categories[i];
                final color = _categoryColors[c.id] ?? AppColors.primaryGreen;
                final icon = _categoryIcons[c.id] ?? Icons.spa_rounded;
                return GestureDetector(
                  onTap: () => context.push(AppRoutes.categoryProductsPath(c.id)),
                  child: SizedBox(
                    width: 84,
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
