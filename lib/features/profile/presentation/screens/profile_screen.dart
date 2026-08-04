import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.valueOrNull;
    final isLoggedIn = user != null && !user.isGuest;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primaryGreen, AppColors.primaryGreenDark]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    isLoggedIn ? user.name.substring(0, 1).toUpperCase() : 'N',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn ? user.name : 'Welcome, Guest',
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      if (isLoggedIn)
                        Text(user.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5))
                      else
                        Text('Sign in to track orders & save favourites', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5)),
                    ],
                  ),
                ),
                if (!isLoggedIn)
                  TextButton(
                    style: TextButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryGreen),
                    onPressed: () => context.push(AppRoutes.login),
                    child: Text('common.signIn'.tr()),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _MenuSection(title: 'My Account', items: [
            _MenuItem(Icons.receipt_long_outlined, 'My Orders', () => context.push(AppRoutes.orders)),
            _MenuItem(Icons.favorite_border_rounded, 'Wishlist', () => context.push(AppRoutes.wishlist)),
            _MenuItem(Icons.location_on_outlined, 'Saved Addresses', () => context.push(AppRoutes.addresses)),
          ]),
          const SizedBox(height: 16),
          _MenuSection(title: 'Preferences', items: [
            _MenuItem(Icons.settings_outlined, 'settings.title'.tr(), () => context.push(AppRoutes.settings)),
          ]),
          const SizedBox(height: 16),
          _MenuSection(title: 'Company', items: [
            _MenuItem(Icons.info_outline_rounded, 'About Us', () => context.push(AppRoutes.about)),
            _MenuItem(Icons.support_agent_rounded, 'Contact Us', () => context.push(AppRoutes.contact)),
            _MenuItem(Icons.description_outlined, 'Terms & Conditions', () => context.push(AppRoutes.terms)),
            _MenuItem(Icons.privacy_tip_outlined, 'Privacy Policy', () => context.push(AppRoutes.privacy)),
          ]),
          if (isLoggedIn) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => ref.read(authRepositoryProvider).logout(),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: Text('common.logOut'.tr(), style: const TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});
  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(entry.value.icon, color: AppColors.primaryGreen),
                    title: Text(entry.value.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: entry.value.onTap,
                  ),
                  if (!isLast) const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
