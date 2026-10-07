import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Typography tokens from Figma (font family Inter).
///
/// Every style is a compile-time constant, so widgets can stay `const`.
/// Conversion rules:
/// * `height = lineHeightPx / fontSize` (Figma line height → Flutter factor);
/// * `letterSpacing` is already in logical px (Figma `tracking-[...]`);
/// * `leadingDistribution: even` splits extra leading evenly above and below
///   the glyphs, exactly like Figma does.
abstract final class AppTextStyles {
  static const String fontFamily = 'Inter';

  /// 34/41 Bold — "PlacesCatalog", "My Places", "42".
  static const TextStyle largeTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    height: 41 / 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.85,
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 22/28 Bold — profile name.
  static const TextStyle title2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 17/22 SemiBold — buttons, header titles, stat values.
  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 17/23.38 SemiBold — place card title.
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 23.38 / 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 17 Regular, normal line height — text inside input fields.
  static const TextStyle input = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 17/22 Regular — settings rows.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 15/20 Regular — links, nav back button, secondary copy.
  static const TextStyle subheadline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 15/18.75 Regular — subtitle under the auth title.
  static const TextStyle authSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 18.75 / 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 15 Regular — search field text.
  static const TextStyle search = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 15/20 SemiBold — social sign-in buttons.
  static const TextStyle socialLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 13/18 Regular — helper text, card subtitle, divider caption.
  static const TextStyle footnote = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 13/18 Medium — unselected chips, "recorded spots".
  static const TextStyle footnoteMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 13/18 SemiBold — selected chip, rating value.
  static const TextStyle footnoteSemibold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 12/16 Regular — visit date, "Sorted by Recent", stat card caption.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 12/19.5 Regular — legal footnote on auth screens.
  static const TextStyle legal = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 19.5 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 12/16 Medium +0.6 UPPERCASE — "CATALOG & JOURNAL".
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
    color: AppColors.textSecondary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 11/16 SemiBold +0.6 UPPERCASE — field labels ("EMAIL ADDRESS").
  static const TextStyle fieldLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.textSecondary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 11/18 Medium +0.65 UPPERCASE — grouped list headers ("DATA & PRIVACY").
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 18 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.65,
    color: AppColors.textSecondary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 11/13 Medium — tab bar labels and stat tile captions.
  static const TextStyle tabLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 13 / 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );
}
