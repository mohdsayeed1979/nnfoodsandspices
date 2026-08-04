import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class _LegalSection {
  const _LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

class _LegalScaffold extends StatelessWidget {
  const _LegalScaffold({required this.title, required this.intro, required this.sections});
  final String title;
  final String intro;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(intro, style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.grey)),
          const SizedBox(height: 20),
          for (final s in sections) ...[
            Text(s.heading, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(s.body, style: const TextStyle(fontSize: 13, height: 1.6)),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalScaffold(
      title: 'Terms & Conditions',
      intro:
          'These Terms & Conditions govern your use of the ${AppConstants.appName} mobile and web application, '
          'operated by ${AppConstants.companyLegalName}. By creating an account or placing an order, you agree to these terms.',
      sections: const [
        _LegalSection(
          '1. Orders & Acceptance',
          'All orders placed through the app are subject to acceptance and availability. We reserve the right to '
              'refuse or cancel any order at our discretion, including in cases of pricing errors or suspected fraud.',
        ),
        _LegalSection(
          '2. Pricing & Payment',
          'Prices are listed in Indian Rupees (INR) unless otherwise stated and are subject to change without prior '
              'notice. Payment must be completed through one of the supported payment methods at checkout.',
        ),
        _LegalSection(
          '3. Shipping & Delivery',
          'Estimated delivery timelines are provided at checkout and are not guaranteed. Delays caused by courier '
              'partners, weather, or circumstances beyond our control are not the responsibility of the company.',
        ),
        _LegalSection(
          '4. Returns & Refunds',
          'Due to the perishable nature of food products, returns are accepted only for items that are damaged, '
              'defective, or incorrect upon delivery. Please contact customer care within 48 hours of delivery.',
        ),
        _LegalSection(
          '5. Account Responsibility',
          'You are responsible for maintaining the confidentiality of your account credentials and for all activity '
              'that occurs under your account.',
        ),
        _LegalSection(
          '6. Intellectual Property',
          'All content on this app, including the NN Food & Spices name, logo, and product imagery, is the property '
              'of ${AppConstants.companyLegalName} and may not be used without written permission.',
        ),
        _LegalSection(
          '7. Contact',
          'Questions about these Terms can be directed to ${AppConstants.supportEmail}.',
        ),
      ],
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalScaffold(
      title: 'Privacy Policy',
      intro:
          '${AppConstants.companyLegalName} ("we", "us") respects your privacy. This policy explains what data '
          '${AppConstants.appName} collects and how it is used.',
      sections: const [
        _LegalSection(
          '1. Information We Collect',
          'Account details (name, email, phone), delivery addresses, order history, and — with your permission — '
              'device information used for push notifications, camera access for barcode scanning, and microphone '
              'access for voice search.',
        ),
        _LegalSection(
          '2. How We Use Your Information',
          'To process and deliver orders, provide customer support, send order updates and offers (if enabled), and '
              'improve the app experience. We do not sell your personal data to third parties.',
        ),
        _LegalSection(
          '3. Data Storage & Security',
          'Passwords are never stored in plain text. Sensitive session data is stored using platform-level encrypted '
              'storage (Android Keystore / iOS Keychain). Network requests are made exclusively over HTTPS.',
        ),
        _LegalSection(
          '4. Third-Party Services',
          'The app may use third-party services for push notifications (Firebase Cloud Messaging) and payment '
              'processing. These providers process data under their own privacy policies.',
        ),
        _LegalSection(
          '5. Your Rights',
          'You may request access to, correction of, or deletion of your personal data at any time by contacting '
              '${AppConstants.supportEmail}.',
        ),
        _LegalSection(
          '6. Changes to This Policy',
          'We may update this Privacy Policy periodically. Continued use of the app after changes constitutes '
              'acceptance of the updated policy.',
        ),
      ],
    );
  }
}
