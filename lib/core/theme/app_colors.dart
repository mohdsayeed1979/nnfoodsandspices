import 'package:flutter/material.dart';

/// Brand palette sourced from the NN Food & Spices logo.
abstract final class AppColors {
  static const primaryGreen = Color(0xFF5E9C2C);
  static const primaryGreenDark = Color(0xFF3D6E18);
  static const primaryGreenLight = Color(0xFF8BC34A);

  static const primaryOrange = Color(0xFFF36B21);
  static const primaryOrangeLight = Color(0xFFFF9E54);

  static const secondaryWhite = Color(0xFFFFFFFF);
  static const darkBackground = Color(0xFF1A1A1A);
  static const lightGrey = Color(0xFFEAEAEA);

  /// Warm off-white used for card/surface backgrounds — softer than pure
  /// white so cards don't look stark/clinical against the app background.
  static const cardSurface = Color(0xFFFDFBF6);

  static const darkSurface = Color(0xFF242424);
  static const darkSurfaceAlt = Color(0xFF2E2E2E);

  static const success = Color(0xFF2E7D32);
  static const error = Color(0xFFD32F2F);
  static const warning = Color(0xFFF9A825);
  static const info = Color(0xFF1976D2);

  static const textPrimaryLight = Color(0xFF1A1A1A);
  static const textSecondaryLight = Color(0xFF6B6B6B);
  static const textPrimaryDark = Color(0xFFF5F5F5);
  static const textSecondaryDark = Color(0xFFAFAFAF);

  static const divider = Color(0xFFE0E0E0);
  static const dividerDark = Color(0xFF3A3A3A);

  static const ratingStar = Color(0xFFFFB300);

  static const List<Color> heroGradient = [primaryGreen, primaryGreenDark];
  static const List<Color> sunriseGradient = [primaryOrangeLight, primaryOrange];
}
