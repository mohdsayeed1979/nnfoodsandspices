<div align="center">

# 🌶️ NN Food & Spices

**100% Naturally Pure Spices** — a premium cross-platform Flutter app for **[Nujju's Nest Spices Pvt. Ltd.](https://nnfoodsandspices.com)**

[![Flutter](https://img.shields.io/badge/Flutter-3.35.3-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-5E9C2C)](#supported-platforms)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2F%20Feature--First-F36B21)](#architecture)
[![State Management](https://img.shields.io/badge/State-Riverpod-40C4FF?logo=riverpod&logoColor=white)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-Proprietary-lightgrey)](LICENSE)

[Privacy Policy](https://mohdsayeed1979.github.io/nnfoodsandspices/privacy-policy.html) · [Website](https://nnfoodsandspices.com) · [Report an Issue](https://github.com/mohdsayeed1979/nnfoodsandspices/issues)

</div>

---

## Table of Contents

- [Description](#description)
- [Features](#features)
- [Screenshots](#screenshots)
- [Supported Platforms](#supported-platforms)
- [Project Setup](#project-setup)
- [Architecture](#architecture)
- [Folder Structure](#folder-structure)
- [Packages Used](#packages-used)
- [Configuration (API keys, Firebase, Payments)](#configuration)
- [Running the App](#running-the-app)
- [Building for Release](#building-for-release)
- [Testing](#testing)
- [Known Limitations / What's Stubbed](#known-limitations--whats-stubbed)
- [License](#license)
- [Developer](#developer)

---

## Description

NN Food & Spices is the official ordering app for **Nujju's Nest Spices Pvt. Ltd.**, an ISO 9001:2005 certified,
GMP & Halal certified spice manufacturer with over a century of family blending tradition. The app is built from
a single Flutter codebase and ships to **Android, iPhone/iPad, Windows, macOS, Linux, and Web** with a clean,
feature-first architecture designed to plug into a real backend (WooCommerce, payment gateways, Firebase) without
touching UI code.

## Features

- 🏠 Premium home page — hero banner, categories, featured/latest products, testimonials, recipes, newsletter
- 🔍 Real-time search with voice search and barcode scanning
- 🛍️ Product catalog with grid/list views, filtering, sorting, wishlist
- 🛒 Cart with coupons, shipping calculation, and a real checkout flow
- 👤 Auth (email/password + phone OTP), guest checkout, order history, saved addresses
- 🌗 Light / dark / system theming (Material 3)
- 🌍 English, Arabic, and Telugu localization with RTL support
- 🔔 Local notifications, Firebase Cloud Messaging-ready
- 💳 Payment architecture ready for Razorpay, Stripe, PayTabs, Google Pay, Apple Pay
- 📴 Offline-friendly — Hive-backed cart/wishlist/orders/addresses persist locally

## Screenshots

| Home | Product Detail | Cart | Profile |
|---|---|---|---|
| _add screenshot_ | _add screenshot_ | _add screenshot_ | _add screenshot_ |

> Screenshots go in `docs/screenshots/` — replace the placeholders above with `![Home](docs/screenshots/home.png)` etc. once captured from a real device/emulator.

## Supported Platforms

| Platform | Status |
|---|---|
| Android | ✅ Builds & runs (APK/AAB verified on device) |
| Web | ✅ Builds & runs |
| Windows | ✅ Builds & runs |
| iOS | ⚙️ Configured — requires macOS + Xcode to compile |
| macOS | ⚙️ Configured — requires macOS + Xcode to compile |
| Linux | ⚙️ Configured — requires a Linux host to compile |

---

## Project Setup

**Flutter version:** 3.35.3 (stable channel) · Dart 3.9.2 · `sdk: ^3.9.2`

```bash
git clone https://github.com/mohdsayeed1979/nnfoodsandspices.git
cd nnfoodsandspices
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates *.freezed.dart / *.g.dart
flutter analyze
flutter test
```

Generated code (`*.freezed.dart`, `*.g.dart`) is **not** committed to version control — run `build_runner` after every clone or after editing any `@freezed` model.

## Architecture

- **Flutter 3.35 stable**, Material 3, `flutter latest stable` APIs (no deprecated widgets).
- **Riverpod** (`flutter_riverpod`) for state management — plain providers (no codegen) for fast iteration.
- **go_router** with `StatefulShellRoute.indexedStack` for the bottom-navigation shell (Home / Products / Categories / Cart / Profile) plus a root navigator for full-screen routes (product detail, checkout, auth, settings…).
- **Freezed + json_serializable** for immutable domain models (`Product`, `ProductCategory`, `ProductReview`, `Address`, `Order`, `AppUser`).
- **Clean, feature-first architecture**: each feature under `lib/features/<feature>/{data,domain,presentation}` — domain defines interfaces, data implements them, presentation only depends on domain.
- **Repository pattern** throughout — every data source (products, cart, auth, orders, addresses) is hidden behind an interface so the local/offline implementation can be swapped for a real backend without touching UI code.
- **Dio** for networking, isolated in `core/network`, HTTPS-only enforced via interceptor, certificate-pinning-ready.
- **Hive** for structured local persistence (cart, wishlist, orders, addresses, auth users) — chosen over SQLite for its simplicity and zero native code generation.
- **flutter_secure_storage** for the auth session token (Android Keystore / iOS Keychain).
- **easy_localization** for i18n (English / Arabic / Telugu) with automatic RTL for Arabic.
- **responsive_framework** for adaptive breakpoints across phone/tablet/desktop/web.

## Folder Structure

```
lib/
  core/                      # cross-cutting: theme, router, network, storage, env, notifications, shared widgets
    constants/               # brand + company info (real data from nnfoodsandspices.com)
    env/                     # compile-time config (--dart-define-from-file=env.json)
    error/                   # Result<T> / AppFailure
    localization/
    network/                 # DioClient
    notifications/           # local notifications + guarded Firebase Messaging
    router/                  # go_router config + bottom-nav shell
    storage/                 # Hive box registry
    theme/                   # AppColors, AppTheme (light/dark), ThemeMode provider
    widgets/                 # ProductCard, ProductImage, shimmer loaders, WhatsApp FAB…
  features/
    auth/                    # login/register/OTP/social-login (local auth repository)
    cart/                    # cart state (Hive-backed) + totals/coupon logic
    categories/
    checkout/                # address, payment method abstraction, order placement
    home/
    notifications/
    products/                # domain + local seed data + WooCommerce-ready remote repository
    profile/                 # orders, addresses, account hub
    search/                  # realtime search, history, voice search, barcode scan
    settings/                # theme/language/currency, about, contact, legal
    splash/
    wishlist/
tool/
  generate_icon.py           # generates the app icon / adaptive-icon / splash assets (Pillow)
  apply_customer_logo.py     # processes the real company logo into icon/splash assets
assets/
  icon/                      # app icon (full-bleed + adaptive foreground)
  splash/                    # splash mark
  translations/              # en.json / ar.json / te.json
test/                        # unit + widget tests
integration_test/            # full-app boot → navigation integration test
privacy-policy.html          # published via GitHub Pages
index.html                   # GitHub Pages landing page
```

## Packages Used

| Purpose | Package |
|---|---|
| State management | `flutter_riverpod` |
| Routing | `go_router` |
| Models | `freezed_annotation`, `json_annotation` (+ `build_runner`, `freezed`, `json_serializable`) |
| Networking | `dio`, `pretty_dio_logger`, `connectivity_plus` |
| Local storage | `hive`, `hive_flutter`, `shared_preferences`, `flutter_secure_storage` |
| Images / loading | `cached_network_image`, `shimmer`, `skeletonizer` |
| Carousel / UI | `carousel_slider`, `smooth_page_indicator`, `flutter_svg`, `lottie`, `photo_view`, `flutter_rating_bar`, `flutter_staggered_animations`, `badges`, `flutter_animate`, `google_fonts` |
| Icons / splash generation | `flutter_launcher_icons`, `flutter_native_splash` |
| Localization | `easy_localization`, `intl` |
| Firebase (optional, guarded) | `firebase_core`, `firebase_messaging`, `firebase_analytics`, `firebase_crashlytics` |
| Notifications | `flutter_local_notifications` |
| Utilities | `equatable`, `url_launcher`, `share_plus`, `package_info_plus`, `device_info_plus`, `logger`, `uuid`, `crypto`, `webview_flutter`, `permission_handler`, `image_picker`, `mobile_scanner`, `speech_to_text`, `in_app_review`, `flutter_slidable` |
| Responsive layout | `responsive_framework` |
| Testing | `flutter_test`, `integration_test`, `mockito` |

## Configuration

The app runs **fully featured out of the box** against a local seed catalog (35 real products scraped from the live site's category pages) and Cash-on-Delivery checkout — no keys required.

To connect real services, create `env.json` (git-ignored) from `env.example.json` and pass it at build/run time:

```bash
flutter run --dart-define-from-file=env.json
flutter build apk --release --dart-define-from-file=env.json
```

| Key | Enables |
|---|---|
| `WOOCOMMERCE_BASE_URL` / `WOOCOMMERCE_CONSUMER_KEY` / `WOOCOMMERCE_CONSUMER_SECRET` | Live product catalog via the WooCommerce REST API (nnfoodsandspices.com runs WordPress/WooCommerce) instead of local seed data |
| `RAZORPAY_KEY` | Razorpay checkout |
| `STRIPE_PUBLISHABLE_KEY` | Stripe checkout |
| `PAYTABS_PROFILE_ID` | PayTabs checkout |

### Firebase (push notifications, analytics, crashlytics)

Not configured in this build (no project was provisioned). To enable:

1. Create a Firebase project and register the Android (`com.nnfoodsandspices.mobile`) and iOS apps.
2. Drop `google-services.json` into `android/app/` and `GoogleService-Info.plist` into `ios/Runner/` and `macos/Runner/` (already git-ignored).
3. Run `flutterfire configure` to generate `lib/firebase_options.dart`, or wire it manually in `core/notifications/notification_service.dart`.

Without this, the app still works normally — `NotificationService` catches the missing-config error and simply disables FCM, while local notifications keep working.

### Social Sign-In (Google / Apple / Facebook)

Requires the Firebase setup above plus OAuth client IDs (Google), an App ID (Facebook), and Sign in with Apple entitlements (iOS). Until configured, tapping these buttons shows a clear "not configured" message rather than failing silently.

### Android release signing

A real production upload keystore is required for release builds. Create `android/key.properties` (git-ignored, see `android/key.properties.example`) pointing at your keystore:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=/absolute/path/to/upload-keystore.jks
```

Without it, release builds fall back to the debug signing config so `flutter build apk --release` still succeeds locally — but that build **cannot** be uploaded to Play Console as-is.

## Running the App

```bash
flutter run -d chrome              # Web
flutter run -d windows             # Windows desktop
flutter run                        # Android (device/emulator)
```

iOS/macOS require Xcode on a Mac; Linux desktop requires a Linux host — both are configured (icons, bundle IDs, entitlements) but require that host OS to compile.

## Building for Release

```bash
# Android
flutter build apk --release
flutter build appbundle --release   # Play Store AAB

# Web
flutter build web --release

# Windows
flutter build windows --release

# iOS (requires macOS + Xcode)
flutter build ipa --release

# macOS (requires macOS + Xcode)
flutter build macos --release

# Linux (requires a Linux host)
flutter build linux --release
```

## Testing

```bash
flutter test                                   # unit + widget tests
flutter test integration_test/app_test.dart    # full-app integration test (needs a device/Chrome)
```

Coverage includes: `Result`/`AppFailure` unit tests, `LocalProductRepository` filtering/sorting/pagination, cart totals & coupon math (via `ProviderContainer` overrides), a `SplashScreen` widget test, a `HomeScreen` widget test, and an integration test that boots the app through the splash screen and exercises bottom-navigation.

## Known Limitations / What's Stubbed

Built honestly rather than faked — here's exactly what needs real credentials or a different host OS before it's "live":

- **iOS / macOS builds**: configured correctly (Info.plist, bundle ID, icons, entitlements) but require a Mac with Xcode to compile.
- **Linux desktop build**: configured but requires a Linux host toolchain to compile.
- **Live product catalog**: nnfoodsandspices.com is WordPress/WooCommerce with no public API key available to this build. `LocalProductRepository` serves the real scraped category/product names (35 products) with representative pricing; `WooCommerceProductRepository` is fully implemented and activates automatically once API credentials are supplied (see [Configuration](#configuration)).
- **Payments**: Cash on Delivery works end-to-end. Razorpay/Stripe/PayTabs/Google Pay/Apple Pay have a real `PaymentService` abstraction wired into checkout, but report "not configured" until real merchant keys/entitlements are added — no fake success responses.
- **Firebase (push notifications, analytics, crashlytics, social sign-in)**: architecture is in place and fails gracefully without config; needs a real Firebase project to activate.
- **OTP**: functional end-to-end using a demo code shown on-screen (no SMS gateway is configured) — swap in Firebase Phone Auth / MSG91 / Twilio for production.
- **Localization**: full `easy_localization` + RTL infrastructure is wired (English/Arabic/Telugu), with bottom navigation and key auth/settings strings translated. Translating every remaining in-app string is a content task — add keys to `assets/translations/*.json`, no code changes required.
- **Legal pages** (Terms & Privacy Policy): real, complete standard e-commerce boilerplate — have counsel review before production launch.

## License

This project is **proprietary** — All Rights Reserved. See [LICENSE](LICENSE) for details. The repository is public
for portfolio and collaboration purposes only; no license to use, copy, or redistribute this code is granted.

## Developer

Built for **Nujju's Nest Spices Pvt. Ltd.**

- 🌐 [nnfoodsandspices.com](https://nnfoodsandspices.com)
- 📧 [nnfoodandspices@gmail.com](mailto:nnfoodandspices@gmail.com)
- 📱 [Facebook](https://facebook.com/nnfoodandspices) · [Instagram](https://instagram.com/nnfoodandspices/) · [YouTube](https://youtube.com/@anzanz314)
