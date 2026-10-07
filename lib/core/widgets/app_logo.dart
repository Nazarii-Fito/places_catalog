import 'package:flutter/widgets.dart';

import '../constants/app_assets.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// PlacesCatalog app icon.
///
/// * [AppLogo.large] — 80 pt "squircle" with a blue depth shadow (auth);
/// * [AppLogo.small] — 32 pt icon in the top header.
class AppLogo extends StatelessWidget {
  const AppLogo.large({super.key})
    : size = AppSizes.logoLarge,
      radius = AppRadii.logo,
      shadows = AppShadows.appIcon;

  const AppLogo.small({super.key})
    : size = AppSizes.logoSmall,
      // The JPEG has its rounded corners baked in on white; clipping hides
      // the white corners on the tinted header background.
      radius = 7,
      shadows = null;

  final double size;
  final double radius;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(AppAssets.appIcon, fit: BoxFit.cover),
      ),
    );
  }
}
