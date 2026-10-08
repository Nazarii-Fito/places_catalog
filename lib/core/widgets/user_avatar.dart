import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Round profile picture. Shows [initials] when there is no photo
/// ([imageAsset] is `null`) — null safety makes that fallback explicit.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.imageAsset,
    required this.initials,
    this.size = AppSizes.avatar,
  });

  final String? imageAsset;
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String? asset = imageAsset;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
        boxShadow: AppShadows.elevated,
      ),
      child: asset == null
          ? Text(
              initials,
              style: AppTextStyles.largeTitle.copyWith(
                color: AppColors.primary,
              ),
            )
          : Image.asset(asset, width: size, height: size, fit: BoxFit.cover),
    );
  }
}
