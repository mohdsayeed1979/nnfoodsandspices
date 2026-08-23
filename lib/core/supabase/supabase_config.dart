import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration, supplied at build/run time via `--dart-define`
/// (or `--dart-define-from-file=env.json`). When both values are present the
/// app reads its live catalog from Supabase; otherwise it transparently
/// falls back to the WooCommerce client or the bundled seed catalog, so the
/// app always runs with zero configuration.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static bool _initialized = false;

  /// Initializes Supabase exactly once, only when configured. Never throws
  /// out to the caller — a backend misconfiguration must not block app start.
  static Future<void> initIfConfigured() async {
    if (!isConfigured || _initialized) return;
    try {
      // `anonKey` accepts both a legacy anon JWT and a newer sb_publishable_
      // key; `publishableKey` is the current, non-deprecated parameter name.
      await Supabase.initialize(url: url, publishableKey: anonKey);
      _initialized = true;
    } catch (_) {
      // Leave _initialized false; the repository selector will fall back.
    }
  }

  static bool get isReady => _initialized;

  static SupabaseClient get client => Supabase.instance.client;
}
