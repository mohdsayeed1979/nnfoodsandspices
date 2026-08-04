import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nn_food_spices/core/router/app_shell.dart';
import 'package:nn_food_spices/core/storage/hive_service.dart';
import 'package:nn_food_spices/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App boots through splash into the home shell with bottom navigation', (tester) async {
    await EasyLocalization.ensureInitialized();
    await HiveService.init();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('te')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const ProviderScope(child: NnFoodSpicesApp()),
      ),
    );

    // Splash screen shows first, then auto-navigates to Home after ~2.2s.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Switch to the Products tab via bottom navigation.
    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    expect(find.text('All Products'), findsOneWidget);

    // Switch to the Cart tab.
    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('My Cart'), findsOneWidget);
  });
}
