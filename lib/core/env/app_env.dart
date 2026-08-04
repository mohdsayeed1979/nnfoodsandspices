import 'package:flutter/foundation.dart';

/// Optional runtime configuration, supplied at build time via
/// `--dart-define-from-file=env.json` (see `env.example.json`). Every
/// getter has a safe default so the app runs fully featured — against
/// local seed data, with payment providers disabled — with zero
/// configuration.
abstract final class AppEnv {
  static bool get isDebug => kDebugMode;

  static const wooCommerceBaseUrl = String.fromEnvironment('WOOCOMMERCE_BASE_URL');
  static const wooCommerceConsumerKey = String.fromEnvironment('WOOCOMMERCE_CONSUMER_KEY');
  static const wooCommerceConsumerSecret = String.fromEnvironment('WOOCOMMERCE_CONSUMER_SECRET');

  static bool get hasWooCommerceApi =>
      wooCommerceBaseUrl.isNotEmpty &&
      wooCommerceConsumerKey.isNotEmpty &&
      wooCommerceConsumerSecret.isNotEmpty;

  static const razorpayKey = String.fromEnvironment('RAZORPAY_KEY');
  static const stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  static const payTabsProfileId = String.fromEnvironment('PAYTABS_PROFILE_ID');
}
