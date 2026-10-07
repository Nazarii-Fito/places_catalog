import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Figma drop shadows translated to [BoxShadow].
///
/// Figma `x y blur spread` maps 1:1 to `offset`, `blurRadius`, `spreadRadius`.
abstract final class AppShadows {
  /// 0 1 1 black 5 % — fields, cards, social buttons.
  static const List<BoxShadow> subtle = [
    BoxShadow(color: AppColors.shadow5, offset: Offset(0, 1), blurRadius: 1),
  ];

  /// 0 1 2 black 5 % — grouped settings lists.
  static const List<BoxShadow> group = [
    BoxShadow(color: AppColors.shadow5, offset: Offset(0, 1), blurRadius: 2),
  ];

  /// Primary filled button glow.
  static const List<BoxShadow> primaryButton = [
    BoxShadow(
      color: AppColors.primaryShadow25,
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: AppColors.primaryShadow25,
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  /// App icon "squircle" depth on auth screens.
  static const List<BoxShadow> appIcon = [
    BoxShadow(
      color: AppColors.primaryShadow15,
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: AppColors.primaryShadow15,
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  /// Floating elements — "+" button, avatar, edit badge.
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: AppColors.shadow10,
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: AppColors.shadow10,
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  /// Translucent top header and bottom tab bar.
  static const List<BoxShadow> bar = [
    BoxShadow(color: AppColors.shadow4, offset: Offset(0, 1), blurRadius: 8),
  ];

  /// Map marker: 0 10 15 −3 and 0 4 6 −4, black 10 %.
  static const List<BoxShadow> marker = [
    BoxShadow(
      color: AppColors.shadow10,
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: AppColors.shadow10,
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  /// Details sheet lifted over the hero photo: 0 −4 10 black 6 %.
  static const List<BoxShadow> sheet = [
    BoxShadow(color: AppColors.shadow6, offset: Offset(0, -4), blurRadius: 10),
  ];

  /// Floating card over the map: 0 20 25 −5 and 0 8 10 −6, black 10 %.
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: AppColors.shadow10,
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: AppColors.shadow10,
      offset: Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -6,
    ),
  ];
}
