import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _currencyKey = 'currency_code';
const _notificationsKey = 'notifications_enabled';

const supportedCurrencies = {
  'INR': '₹ Indian Rupee',
  'USD': '\$ US Dollar',
  'AED': 'د.إ UAE Dirham',
};

class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier() : super('INR') {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_currencyKey) ?? 'INR';
  }

  Future<void> setCurrency(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) => CurrencyNotifier());

class NotificationsNotifier extends StateNotifier<bool> {
  NotificationsNotifier() : super(true) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_notificationsKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }
}

final notificationsEnabledProvider = StateNotifierProvider<NotificationsNotifier, bool>((ref) => NotificationsNotifier());
