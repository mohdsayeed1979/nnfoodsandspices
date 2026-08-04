import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../products/presentation/providers/product_providers.dart';

const _categoryIcons = <String, IconData>{
  'veg-spices': Icons.eco_rounded,
  'pure-spices': Icons.grass_rounded,
  'non-veg-spices': Icons.set_meal_rounded,
  'other-spices': Icons.local_dining_rounded,
};

const _categoryColors = <String, List<Color>>{
  'veg-spices': [Color(0xFF7CB342), Color(0xFF4A7D22)],
  'pure-spices': [Color(0xFFF9A825), Color(0xFFEF6C00)],
  'non-veg-spices': [Color(0xFFE64A19), Color(0xFFB0280C)],
  'other-spices': [AppColors.primaryOrangeLight, AppColors.primaryOrange],
};

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.3,
          ),
          itemCount: 4,
          itemBuilder: (_, __) => const ShimmerBox(borderRadius: 18),
        ),
        error: (e, _) => const Center(child: Text('Could not load categories')),
        data: (categories) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.3,
          ),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final c = categories[i];
            final colors = _categoryColors[c.id] ?? [AppColors.primaryGreen, AppColors.primaryGreenDark];
            final icon = _categoryIcons[c.id] ?? Icons.spa_rounded;
            return GestureDetector(
              onTap: () => context.push(AppRoutes.categoryProductsPath(c.id)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -14,
                      bottom: -14,
                      child: Icon(icon, size: 90, color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('${c.productCount} products', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
