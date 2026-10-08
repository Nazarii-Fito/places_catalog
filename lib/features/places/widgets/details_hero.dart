import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/pressable_opacity.dart';

/// 260 pt cover photo with a dark gradient, a round favourite button and
/// the "4 Photos" counter — all layered with a [Stack]. Back navigation
/// lives only in the header, so there is a single back button.
class DetailsHero extends StatelessWidget {
  const DetailsHero({
    super.key,
    required this.image,
    required this.photosCount,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final String image;
  final int photosCount;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(image, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.scrim40,
                  AppColors.transparent,
                  AppColors.scrim30,
                ],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.m,
            right: AppSpacing.l,
            child: _GlassCircleButton(
              label: AppStrings.toggleFavorite,
              onTap: onToggleFavorite,
              child: isFavorite
                  ? const AppSvgIcon(
                      AppAssets.iconHeartFilled,
                      width: 18.333,
                      height: 16.821,
                    )
                  : const AppSvgIcon(
                      AppAssets.iconHeartOutline,
                      width: 18.333,
                      height: 16.821,
                      color: AppColors.onPrimary,
                    ),
            ),
          ),
          if (photosCount > 0)
            Positioned(
              left: 20,
              bottom: 40,
              child: _Frosted(
                color: AppColors.scrim45,
                borderRadius: AppRadii.pillAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSpacing.xs,
                    children: [
                      const AppSvgIcon(AppAssets.iconPhoto),
                      Text(
                        '$photosCount${AppStrings.photosSuffix}',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: PressableOpacity(
        onTap: onTap,
        child: _Frosted(
          color: AppColors.scrim40,
          borderRadius: AppRadii.pillAll,
          child: SizedBox.square(
            dimension: AppSpacing.minTapTarget,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Translucent tint with a 6 pt backdrop blur (iOS "material" look).
class _Frosted extends StatelessWidget {
  const _Frosted({
    required this.color,
    required this.borderRadius,
    required this.child,
  });

  final Color color;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: ColoredBox(color: color, child: child),
      ),
    );
  }
}
