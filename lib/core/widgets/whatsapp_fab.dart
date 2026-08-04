import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

class WhatsAppFab extends StatelessWidget {
  const WhatsAppFab({super.key});

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/${AppConstants.whatsappNumber}?text=${Uri.encodeComponent("Hi NN Food & Spices, I'd like to know more about your products.")}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'whatsapp-fab',
      backgroundColor: const Color(0xFF25D366),
      onPressed: _openWhatsApp,
      child: const Icon(Icons.chat, color: Colors.white),
    );
  }
}
