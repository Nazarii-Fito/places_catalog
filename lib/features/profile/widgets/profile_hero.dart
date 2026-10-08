import 'package:flutter/widgets.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/pressable_opacity.dart';
import '../../../core/widgets/user_avatar.dart';

/// Avatar with the "edit profile" badge, name and e-mail.
///
/// The badge overlaps the avatar's bottom-right corner — a [Stack] with
/// `Clip.none` lets it stick out of the circle as in Figma.
class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.name,
    required this.email,
    required this.avatarAsset,
    required this.initials,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String? avatarAsset;
  final String initials;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.m),
        Stack(
          clipBehavior: Clip.none,
          children: [
            UserAvatar(imageAsset: avatarAsset, initials: initials),
            // 44 pt hit area centred on the 36 pt badge.
            Positioned(
              right: -8,
              bottom: -8,
              child: Semantics(
                button: true,
                label: AppStrings.editProfilePhoto,
                child: PressableOpacity(
                  onTap: onEdit,
                  child: SizedBox.square(
                    dimension: AppSpacing.minTapTarget,
                    child: Center(
                      child: Container(
                        width: AppSizes.avatarBadge,
                        height: AppSizes.avatarBadge,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.elevated,
                        ),
                        child: const AppSvgIcon(AppAssets.iconPencil),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Text(name, style: AppTextStyles.title2, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          email,
          style: AppTextStyles.footnote.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.m),
      ],
    );
  }
}
