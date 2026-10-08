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
  static const Color surfaceContainerHighest = Color(0xFFE3E2E7);

  /// #F4F3F8 at 70 % — notes box on Place Details.
  static const Color surfaceContainerLowTranslucent = Color(0xB3F4F3F8);

  /// Translucent background of the top header and the bottom tab bar (85 %).
  static const Color barBackground = Color(0xD9FAF9FE);

  // Brand
  static const Color primary = Color(0xFF0058BC);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Primary at 10 % — tinted circles behind icons.
  static const Color primaryTint = Color(0x1A0058BC);

  /// Blurred glow behind the app logo on auth screens (#D8E2FF at 30 %).
  static const Color ambientGlow = Color(0x4DD8E2FF);

  /// #D8E2FF at 20 % — "Add Photos" panel.
  static const Color primaryContainerSoft = Color(0x33D8E2FF);

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

  /// Sheet drag handle (#C1C6D7 at 60 %).
  static const Color handle = Color(0x99C1C6D7);

  /// Separator above the "Add tag" input (#E9E7ED at 60 %).
  static const Color tagDivider = Color(0x99E9E7ED);

  // Semantic accents
  static const Color destructive = Color(0xFFBA1A1A);

  /// #FFDAD6 at 60 % — background of the "Delete Place" button.
  static const Color destructiveContainer = Color(0x99FFDAD6);
  static const Color star = Color(0xFFFE9400);
  static const Color cafeAccent = Color(0xFF8C5000);

  // Overlays on photos and maps
  static const Color scrim5 = Color(0x0D000000);
  static const Color scrim10 = Color(0x1A000000);
  static const Color scrim30 = Color(0x4D000000);
  static const Color scrim40 = Color(0x66000000);
  static const Color scrim45 = Color(0x73000000);
  static const Color transparent = Color(0x00000000);

  /// Small "remove photo" button (#2F3034 at 75 %).
  static const Color photoRemoveBackground = Color(0xBF2F3034);

  /// Frosted white panels over the map.
  static const Color glass85 = Color(0xD9FFFFFF);
  static const Color glass90 = Color(0xE6FFFFFF);
  static const Color glass95 = Color(0xF2FFFFFF);

  /// Search capsule over the map (#E3E2E7 at 60 %).
  static const Color mapSearchBackground = Color(0x99E3E2E7);

  // Shadows (black / primary with alpha)
  static const Color shadow4 = Color(0x0A000000);
  static const Color shadow5 = Color(0x0D000000);
  static const Color shadow6 = Color(0x0F000000);
  static const Color shadow10 = Color(0x1A000000);
  static const Color primaryShadow15 = Color(0x260058BC);
  static const Color primaryShadow25 = Color(0x400058BC);
}
