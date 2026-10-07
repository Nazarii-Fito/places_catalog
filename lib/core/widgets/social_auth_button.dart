import 'package:flutter/widgets.dart';

import '../constants/app_assets.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_svg_icon.dart';
import 'pressable_opacity.dart';

/// Third-party sign-in providers shown on the auth screens.
enum SocialProvider { apple, google }

/// White "Apple" / "Google" sign-in button (UI only, no real OAuth).
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.provider,
    required this.onPressed,
  });

  final SocialProvider provider;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (String icon, String label) = switch (provider) {
      SocialProvider.apple => (AppAssets.iconApple, AppStrings.apple),
      SocialProvider.google => (AppAssets.iconGoogle, AppStrings.google),
    };
    return Semantics(
      button: true,
      child: PressableOpacity(
        onTap: onPressed,
        child: Container(
          height: AppSizes.socialButtonHeight,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.mdAll,
            boxShadow: AppShadows.subtle,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Both logos sit in a 20×20 frame in Figma.
              SizedBox.square(
                dimension: 20,
                child: Center(child: AppSvgIcon(icon)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: AppTextStyles.socialLabel),
            ],
          ),
        ),
      ),
    );
  }
}
