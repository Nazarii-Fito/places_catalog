import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'pressable_opacity.dart';

/// Inline blue text action ("Forgot Password?", "Log In", "Resend").
///
/// The visible text is small, but the tappable area is at least
/// 44 pt high as required by Apple HIG.
class AppTextLink extends StatelessWidget {
  const AppTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.style = AppTextStyles.subheadline,
    this.horizontalPadding = AppSpacing.sm,
  });

  final String label;
  final VoidCallback onTap;
  final TextStyle style;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: PressableOpacity(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: style.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
