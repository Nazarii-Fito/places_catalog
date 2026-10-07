import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'pressable_opacity.dart';

/// Filled blue confirm button — "Log In", "Create Account", "Save", ...
///
/// * [label] — button text (named parameter, required);
/// * [onPressed] — `null` renders the disabled state;
/// * [icon] — optional leading widget (e.g. "Confirm Location").
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Widget? leading = icon;
    return Semantics(
      button: true,
      enabled: enabled,
      child: PressableOpacity(
        onTap: onPressed,
        pressedOpacity: 0.85,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            height: AppSizes.buttonHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadii.mdAll,
              boxShadow: enabled ? AppShadows.primaryButton : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  label,
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
