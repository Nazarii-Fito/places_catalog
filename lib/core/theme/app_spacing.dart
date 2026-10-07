/// Spacing scale used across the Figma frames (logical px).
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 6;
  static const double sm = 8;
  static const double m = 12;
  static const double ml = 14;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal padding of every screen.
  static const double screen = 16;

  /// Minimum tappable size required by Apple HIG.
  static const double minTapTarget = 44;
}

/// Fixed component sizes from Figma.
abstract final class AppSizes {
  static const double fieldHeight = 52;
  static const double buttonHeight = 52;
  static const double socialButtonHeight = 48;
  static const double searchHeight = 40;
  static const double chipHeight = 32;
  static const double headerHeight = 56;
  static const double tabBarHeight = 64;
  static const double placeThumbnail = 84;
  static const double avatar = 96;
  static const double avatarBadge = 36;
  static const double logoLarge = 80;
  static const double logoSmall = 32;
}
