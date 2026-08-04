import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class _Banner {
  const _Banner(this.title, this.subtitle, this.cta, this.colors, this.icon, this.categoryId);
  final String title;
  final String subtitle;
  final String cta;
  final List<Color> colors;
  final IconData icon;
  final String? categoryId;
}

const _banners = [
  _Banner(
    '100% Naturally Pure Spices',
    'Handcrafted blends, zero artificial colours',
    'Shop Now',
    [AppColors.primaryGreen, AppColors.primaryGreenDark],
    Icons.eco_rounded,
    null,
  ),
  _Banner(
    'Non-Veg Masala Collection',
    'Biryani, Chicken, Mutton & Fish blends',
    'Explore',
    [Color(0xFFE64A19), Color(0xFFB0280C)],
    Icons.set_meal_rounded,
    'non-veg-spices',
  ),
  _Banner(
    'Pure Ground Spices',
    'Single-ingredient spices, GMP & Halal certified',
    'Discover',
    [Color(0xFFF9A825), Color(0xFFEF6C00)],
    Icons.grass_rounded,
    'pure-spices',
  ),
  _Banner(
    'Veg Masala Blends',
    '100% vegetarian ingredients for every dish',
    'Browse',
    [AppColors.primaryGreenLight, AppColors.primaryGreen],
    Icons.local_dining_rounded,
    'veg-spices',
  ),
];

class HeroBannerSlider extends StatefulWidget {
  const HeroBannerSlider({super.key});

  @override
  State<HeroBannerSlider> createState() => _HeroBannerSliderState();
}

class _HeroBannerSliderState extends State<HeroBannerSlider> {
  final _controller = CarouselSliderController();
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          carouselController: _controller,
          options: CarouselOptions(
            height: 170,
            viewportFraction: 0.92,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            enlargeCenterPage: true,
            onPageChanged: (index, _) => setState(() => _current = index),
          ),
          items: _banners.map((banner) {
            return GestureDetector(
              onTap: () => banner.categoryId == null
                  ? context.push(AppRoutes.products)
                  : context.push(AppRoutes.categoryProductsPath(banner.categoryId!)),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: banner.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -20,
                      child: Icon(banner.icon, size: 110, color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          banner.title,
                          style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700, height: 1.2),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          banner.subtitle,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            banner.cta,
                            style: TextStyle(color: banner.colors.last, fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        AnimatedSmoothIndicator(
          activeIndex: _current,
          count: _banners.length,
          effect: const WormEffect(
            dotHeight: 6,
            dotWidth: 6,
            activeDotColor: AppColors.primaryGreen,
            dotColor: AppColors.divider,
          ),
        ),
      ],
    );
  }
}
