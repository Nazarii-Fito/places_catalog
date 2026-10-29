import 'package:flutter/cupertino.dart';

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
/// * [icon] — optional leading widget (e.g. "Confirm Location");
/// * [isLoading] — shows a spinner instead of the label and ignores taps,
///   so a request cannot be sent twice.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = AppSizes.buttonHeight,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  /// 52 pt by default; Add Place uses a 48 pt variant.
  final double height;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // While loading the button keeps its full colour but is not tappable.
    final bool enabled = onPressed != null || isLoading;
    final Widget? leading = icon;
    return Semantics(
      button: true,
      enabled: enabled && !isLoading,
      child: PressableOpacity(
        onTap: isLoading ? null : onPressed,
        pressedOpacity: 0.85,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadii.mdAll,
              boxShadow: enabled ? AppShadows.primaryButton : null,
            ),
            child: isLoading
                ? const CupertinoActivityIndicator(color: AppColors.onPrimary)
                : Row(
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
