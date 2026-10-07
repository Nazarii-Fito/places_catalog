import 'package:flutter/widgets.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/pressable_opacity.dart';

/// Red "Log Out" row in its own inset group ("Danger Zone").
class LogOutButton extends StatelessWidget {
  const LogOutButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: PressableOpacity(
        onTap: onPressed,
        pressedOpacity: 0.5,
        child: Container(
          height: AppSizes.buttonHeight,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.mdAll,
            boxShadow: AppShadows.group,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppSvgIcon(AppAssets.iconLogout),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppStrings.logOut,
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
