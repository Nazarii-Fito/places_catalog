import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'pressable_opacity.dart';

/// Outlined button for the secondary action ("Create Account" on Login).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: PressableOpacity(
        onTap: onPressed,
        child: Container(
          height: AppSizes.buttonHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadii.mdAll,
            border: Border.all(color: AppColors.primary),
          ),
          child: Text(
            label,
            style: AppTextStyles.headline.copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
