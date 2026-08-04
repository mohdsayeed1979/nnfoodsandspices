import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';

Future<void> _openUrl(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

class WhyChooseUsSection extends StatelessWidget {
  const WhyChooseUsSection({super.key});

  static const _points = [
    (Icons.verified_rounded, '100% Natural', 'No artificial colours or fillers, ever.'),
    (Icons.eco_rounded, 'GMP & Halal Certified', 'Every blend meets strict quality standards.'),
    (Icons.local_shipping_outlined, 'Fresh Delivery', 'Ground and packed close to dispatch.'),
    (Icons.emoji_events_outlined, '100+ Years of Blending', 'Family recipes perfected over generations.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Why Choose Us'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: _points.map((p) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(p.$1, color: AppColors.primaryGreen, size: 26),
                    const Spacer(),
                    Text(p.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(p.$3, style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), maxLines: 2),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  static const _testimonials = [
    ('Priya Sharma', 'Hyderabad', 'The biryani masala tastes exactly like my grandmother\'s recipe. Absolutely authentic!'),
    ('Rahul Verma', 'Bengaluru', 'Freshest spices I\'ve bought online. The aroma alone tells you it\'s pure quality.'),
    ('Ayesha Khan', 'Mumbai', 'Been ordering the garam masala for a year now — consistent quality every single time.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'What Our Customers Say'),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _testimonials.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final t = _testimonials[i];
              return Container(
                width: 260,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded, color: AppColors.primaryOrange, size: 22),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(t.$3, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, height: 1.4)),
                    ),
                    const SizedBox(height: 6),
                    Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    Text(t.$2, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class RecipeIdeasSection extends StatelessWidget {
  const RecipeIdeasSection({super.key});

  static const _recipes = [
    ('Hyderabadi Chicken Biryani', 'Made with our Chicken Biryani Masala', Icons.rice_bowl_rounded),
    ('Paneer Tikka Skewers', 'Made with our Paneer Tikka Masala', Icons.kebab_dining_rounded),
    ('Mumbai Pav Bhaji', 'Made with our Pav Bhaji Masala', Icons.lunch_dining_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recipe Ideas', subtitle: 'Cook restaurant-style dishes at home'),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recipes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final r = _recipes[i];
              return Container(
                width: 220,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primaryOrangeLight, AppColors.primaryOrange]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(r.$3, color: Colors.white, size: 26),
                    const SizedBox(height: 14),
                    Text(r.$1, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(r.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SocialAndNewsSection extends StatelessWidget {
  const SocialAndNewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Stay Connected', subtitle: 'Latest updates from NN Food & Spices'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _SocialTile(
                  icon: Icons.facebook_rounded,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () => _openUrl(AppConstants.facebookUrl),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SocialTile(
                  icon: Icons.camera_alt_rounded,
                  label: 'Instagram',
                  color: const Color(0xFFE1306C),
                  onTap: () => _openUrl(AppConstants.instagramUrl),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SocialTile(
                  icon: Icons.play_circle_fill_rounded,
                  label: 'YouTube',
                  color: const Color(0xFFFF0000),
                  onTap: () => _openUrl(AppConstants.youtubeUrl),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialTile extends StatelessWidget {
  const _SocialTile({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsletterSection extends StatefulWidget {
  const NewsletterSection({super.key});

  @override
  State<NewsletterSection> createState() => _NewsletterSectionState();
}

class _NewsletterSectionState extends State<NewsletterSection> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Subscribe to Our Newsletter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Get offers, new arrivals and recipes in your inbox.', style: TextStyle(fontSize: 12.5)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Your email address',
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _controller.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Subscribed! Thank you for joining us.')),
                      );
                    }
                  },
                  child: const Text('Join'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContactSection extends StatelessWidget {
  const HomeContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Get in Touch'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppConstants.companyLegalName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              const SizedBox(height: 8),
              _ContactRow(icon: Icons.location_on_outlined, text: AppConstants.address),
              _ContactRow(icon: Icons.phone_outlined, text: AppConstants.customerCarePhone, onTap: () => _openUrl('tel:${AppConstants.customerCarePhone}')),
              _ContactRow(icon: Icons.email_outlined, text: AppConstants.supportEmail, onTap: () => _openUrl('mailto:${AppConstants.supportEmail}')),
              _ContactRow(icon: Icons.language_outlined, text: AppConstants.websiteUrl, onTap: () => _openUrl(AppConstants.websiteUrl)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text, this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: AppColors.primaryGreen),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.3))),
          ],
        ),
      ),
    );
  }
}
