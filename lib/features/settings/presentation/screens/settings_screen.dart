import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../settings_provider.dart';

const _supportedLocales = [
  (Locale('en'), 'English'),
  (Locale('ar'), 'العربية'),
  (Locale('te'), 'తెలుగు'),
];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final currency = ref.watch(currencyProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Appearance',
            children: [
              RadioGroup<ThemeMode>(
                groupValue: themeMode,
                onChanged: (v) => ref.read(themeModeProvider.notifier).setThemeMode(v!),
                child: const Column(children: [
                  _RadioTile<ThemeMode>(title: 'Light', icon: Icons.light_mode_outlined, value: ThemeMode.light),
                  _RadioTile<ThemeMode>(title: 'Dark', icon: Icons.dark_mode_outlined, value: ThemeMode.dark),
                  _RadioTile<ThemeMode>(title: 'System Default', icon: Icons.settings_suggest_outlined, value: ThemeMode.system),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Language',
            children: [
              RadioGroup<Locale>(
                groupValue: context.locale,
                onChanged: (v) => context.setLocale(v!),
                child: Column(
                  children: _supportedLocales.map((entry) {
                    return _RadioTile<Locale>(title: entry.$2, icon: Icons.language_rounded, value: entry.$1);
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Currency',
            children: [
              RadioGroup<String>(
                groupValue: currency,
                onChanged: (v) => ref.read(currencyProvider.notifier).setCurrency(v!),
                child: Column(
                  children: supportedCurrencies.entries.map((entry) {
                    return _RadioTile<String>(title: entry.value, icon: Icons.currency_exchange_rounded, value: entry.key);
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_outlined, color: AppColors.primaryGreen),
                title: const Text('Order updates & offers', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                value: notificationsEnabled,
                activeThumbColor: AppColors.primaryGreen,
                onChanged: (v) => ref.read(notificationsEnabledProvider.notifier).setEnabled(v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'About',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline_rounded, color: AppColors.primaryGreen),
                title: const Text('About Us', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.about),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined, color: AppColors.primaryGreen),
                title: const Text('Terms & Conditions', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.terms),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primaryGreen),
                title: const Text('Privacy Policy', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.privacy),
              ),
              const _AppVersionTile(),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppVersionTile extends StatelessWidget {
  const _AppVersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})' : '...';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.tag_rounded, color: AppColors.primaryGreen),
          title: const Text('App Version', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          trailing: Text(version, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

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
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  const _RadioTile({required this.title, required this.icon, required this.value});
  final String title;
  final IconData icon;
  final T value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      contentPadding: EdgeInsets.zero,
      value: value,
      activeColor: AppColors.primaryGreen,
      secondary: Icon(icon, color: AppColors.primaryGreen),
      title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
    );
  }
}
