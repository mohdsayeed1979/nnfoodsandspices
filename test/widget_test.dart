import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nn_food_spices/core/constants/app_constants.dart';
import 'package:nn_food_spices/features/splash/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen shows the app name and tagline', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.tagline), findsOneWidget);

    // Unmount before the test ends so SplashScreen.dispose() cancels its
    // pending navigation timer (otherwise flutter_test's FakeAsync check
    // for leaked timers fails the test).
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
