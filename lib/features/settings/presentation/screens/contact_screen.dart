import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primaryGreen, AppColors.primaryGreenDark]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.companyLegalName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(AppConstants.address, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ContactTile(icon: Icons.support_agent_rounded, title: 'Customer Care / Orders', subtitle: AppConstants.customerCarePhone, onTap: () => _open('tel:${AppConstants.customerCarePhone}')),
          _ContactTile(icon: Icons.badge_outlined, title: 'Official / Export', subtitle: AppConstants.officialPhone, onTap: () => _open('tel:${AppConstants.officialPhone}')),
          _ContactTile(icon: Icons.business_center_outlined, title: 'Corporate / Marketing', subtitle: AppConstants.corporatePhone, onTap: () => _open('tel:${AppConstants.corporatePhone}')),
          _ContactTile(icon: Icons.email_outlined, title: 'Email', subtitle: AppConstants.supportEmail, onTap: () => _open('mailto:${AppConstants.supportEmail}')),
          _ContactTile(icon: Icons.language_rounded, title: 'Website', subtitle: AppConstants.websiteUrl, onTap: () => _open(AppConstants.websiteUrl)),
          _ContactTile(icon: Icons.chat_rounded, title: 'WhatsApp', subtitle: '+${AppConstants.whatsappNumber}', onTap: () => _open('https://wa.me/${AppConstants.whatsappNumber}')),
          _ContactTile(
            icon: Icons.map_outlined,
            title: 'Find Us on Google Maps',
            subtitle: 'Shamshabad, Ranga Reddy District, Telangana',
            onTap: () => _open('https://www.google.com/maps/search/?api=1&query=${AppConstants.googleMapsQuery}'),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryGreen),
        title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }
}
