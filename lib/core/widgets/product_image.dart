import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Renders a real product photo when [imageUrl] is a live network URL
/// (populated once the WooCommerce API is connected). Until then it shows a
/// tasteful branded placeholder — a category-tinted gradient tile with an
/// icon and the product's initials — never a fabricated stock photo.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.categoryName,
    this.borderRadius,
    this.heroTag,
  });

  final String imageUrl;
  final String name;
  final String categoryName;
  final BorderRadius? borderRadius;
  final Object? heroTag;

  static const _palette = <String, List<Color>>{
    'veg-spices': [Color(0xFF7CB342), Color(0xFF4A7D22)],
    'pure-spices': [Color(0xFFF9A825), Color(0xFFEF6C00)],
    'non-veg-spices': [Color(0xFFE64A19), Color(0xFFB0280C)],
    'other-spices': [AppColors.primaryOrangeLight, AppColors.primaryOrange],
  };

  static const _icons = <String, IconData>{
    'veg-spices': Icons.eco_rounded,
    'pure-spices': Icons.grass_rounded,
    'non-veg-spices': Icons.set_meal_rounded,
    'other-spices': Icons.local_dining_rounded,
  };

  String get _key => categoryName.toLowerCase().replaceAll(' ', '-');

  String get _initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return 'NN';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final content = imageUrl.startsWith('http')
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: AppColors.lightGrey,
              highlightColor: Colors.white,
              child: Container(color: Colors.white),
            ),
            errorWidget: (context, url, error) => _placeholder(context),
          )
        : _placeholder(context);

    final child = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: content,
    );

    return heroTag != null ? Hero(tag: heroTag!, child: child) : child;
  }

  Widget _placeholder(BuildContext context) {
    final colors = _palette[_key] ?? _palette['pure-spices']!;
    final icon = _icons[_key] ?? Icons.spa_rounded;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -18,
            bottom: -18,
            child: Icon(icon, size: 84, color: Colors.white.withValues(alpha: 0.18)),
          ),
          Text(
            _initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
