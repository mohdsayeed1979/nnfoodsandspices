import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
              child: Image.asset('assets/splash/splash_logo.png'),
            ),
          ),
          const SizedBox(height: 16),
          Text(AppConstants.companyLegalName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(AppConstants.isoCertification, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          const _AboutParagraph(
            'For over a century, our family has mastered the art of blending spices — combining '
            'traditional recipes with strict quality standards to bring you 100% naturally pure spices, '
            'free from artificial colours and fillers.',
          ),
          const SizedBox(height: 16),
          const _AboutParagraph(
            'Every product is GMP and Halal certified, ground and packed close to dispatch to preserve '
            'freshness and aroma — from our kitchen to yours.',
          ),
          const SizedBox(height: 24),
          const _StatsRow(),
          const SizedBox(height: 24),
          const Text('Our Values', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const _ValueRow(icon: Icons.eco_rounded, title: '100% Natural', subtitle: 'No artificial colours or preservatives'),
          const _ValueRow(icon: Icons.verified_rounded, title: 'Certified Quality', subtitle: 'GMP & Halal certified processes'),
          const _ValueRow(icon: Icons.groups_rounded, title: 'Family Tradition', subtitle: 'Recipes passed down through generations'),
        ],
      ),
    );
  }
}

class _AboutParagraph extends StatelessWidget {
  const _AboutParagraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 13.5, height: 1.6));
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    const stats = [('100+', 'Years of Blending'), ('4', 'Product Categories'), ('35+', 'Spice Blends')];
    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Column(
            children: [
              Text(s.$1, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
              const SizedBox(height: 2),
              Text(s.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
