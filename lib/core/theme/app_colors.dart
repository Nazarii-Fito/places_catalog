import 'package:flutter/painting.dart';

/// Colour tokens extracted from the PlacesCatalog Figma file.
///
/// This is the only place in the app where raw `Color(0x...)` literals are
/// allowed. Screens and widgets reference these semantic names, so a dark
/// palette can be added later without touching the UI code.
abstract final class AppColors {
  // Surfaces
  static const Color background = Color(0xFFFAF9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEEEDF3);
  static const Color surfaceContainerLow = Color(0xFFF4F3F8);
  static const Color surfaceContainerHigh = Color(0xFFE9E7ED);

  /// Translucent background of the top header and the bottom tab bar (85 %).
  static const Color barBackground = Color(0xD9FAF9FE);

  // Brand
  static const Color primary = Color(0xFF0058BC);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Primary at 10 % — tinted circles behind icons.
  static const Color primaryTint = Color(0x1A0058BC);

  /// Blurred glow behind the app logo on auth screens (#D8E2FF at 30 %).
  static const Color ambientGlow = Color(0x4DD8E2FF);

  // Text
  static const Color textPrimary = Color(0xFF1A1B1F);
  static const Color textSecondary = Color(0xFF414755);
  static const Color textTertiary = Color(0xFF717786);

  /// Helper text under fields (#414755 at 80 %).
  static const Color textHelper = Color(0xCC414755);

  // Lines & placeholders
  static const Color outlineVariant = Color(0xFFC1C6D7);

  /// Hairline dividers (#C1C6D7 at 40 %).
  static const Color divider = Color(0x66C1C6D7);

  // Semantic accents
  static const Color destructive = Color(0xFFBA1A1A);
  static const Color star = Color(0xFFFE9400);
  static const Color success = Color(0xFF006B27);

  /// Success at 10 % — background of the "Active" status badge.
  static const Color successTint = Color(0x1A006B27);
  static const Color cafeAccent = Color(0xFF8C5000);

  // Shadows (black / primary with alpha)
  static const Color shadow4 = Color(0x0A000000);
  static const Color shadow5 = Color(0x0D000000);
  static const Color shadow10 = Color(0x1A000000);
  static const Color primaryShadow15 = Color(0x260058BC);
  static const Color primaryShadow25 = Color(0x400058BC);
}
