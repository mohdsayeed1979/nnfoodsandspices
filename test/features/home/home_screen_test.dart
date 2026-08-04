import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nn_food_spices/features/home/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/hive_test_setup.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    EasyLocalization.logger.enableLevels = [];
    await EasyLocalization.ensureInitialized();
    hiveDir = await initTestHive();
  });

  tearDownAll(() async {
    await disposeTestHive(hiveDir);
  });

  testWidgets('HomeScreen renders the search bar and hero banner', (tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('te')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const ProviderScope(
          child: MaterialApp(home: HomeScreen()),
        ),
      ),
    );
    // Allow EasyLocalization + FutureProviders to settle.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Search for spices, masalas...'), findsOneWidget);
    expect(find.text('Featured Products'), findsOneWidget);

    // Scroll down to bring further sections into the render tree.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Why Choose Us'), findsOneWidget);
  });
}
