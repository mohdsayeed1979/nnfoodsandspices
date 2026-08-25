import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/constants/app_constants.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_service.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/updates/app_update_service.dart';
import 'features/products/presentation/providers/product_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await HiveService.init();
  // Connects to the live Supabase catalog when SUPABASE_URL + anon key are
  // provided via --dart-define; otherwise a no-op and the app uses the
  // bundled seed catalog. Never throws out — a backend outage must not
  // block app startup.
  await SupabaseConfig.initIfConfigured();
  // Fire-and-forget: local notifications always succeed, Firebase Cloud
  // Messaging silently stays disabled until a real project is wired up —
  // neither should block app startup.
  NotificationService.instance.init();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('te')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: NnFoodSpicesApp()),
    ),
  );
}

class NnFoodSpicesApp extends ConsumerStatefulWidget {
  const NnFoodSpicesApp({super.key});

  @override
  ConsumerState<NnFoodSpicesApp> createState() => _NnFoodSpicesAppState();
}

final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class _NnFoodSpicesAppState extends ConsumerState<NnFoodSpicesApp> with WidgetsBindingObserver {
  late final AppUpdateService _updateService = AppUpdateService(_scaffoldMessengerKey);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check Google Play for a newer version once the first frame is up, so
    // the check never delays startup. No-op on non-Android / debug builds.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateService.checkForUpdate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Mobile apps are far more often backgrounded than fully restarted — the
  // OS keeps the process (and every cached Riverpod value) alive for days.
  // Without this, an admin-side catalog change (new product image, price,
  // stock) would never reach a session that's just resumed from the
  // background, even though `.autoDispose` already fixes the
  // navigate-away-and-back case. Invalidating on resume is lazy — it only
  // clears the cached Future, the actual re-fetch happens naturally the next
  // time a still-mounted widget (e.g. the Home screen) watches it again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(featuredProductsProvider);
      ref.invalidate(latestProductsProvider);
      ref.invalidate(categoriesProvider);
      // Re-check for a Play Store update on resume (guarded so it won't
      // re-prompt once an update has already been downloaded this session).
      _updateService.checkForUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: child ?? const SizedBox(),
          breakpoints: const [
            Breakpoint(start: 0, end: 480, name: MOBILE),
            Breakpoint(start: 481, end: 800, name: TABLET),
            Breakpoint(start: 801, end: 1280, name: DESKTOP),
            Breakpoint(start: 1281, end: double.infinity, name: '4K'),
          ],
        );
      },
    );
  }
}
