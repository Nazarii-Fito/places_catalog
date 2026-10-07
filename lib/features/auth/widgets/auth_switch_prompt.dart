import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_link.dart';

/// Centered "Already have an account? **Log In**" row.
class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onAction,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            question,
            style: AppTextStyles.subheadline.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        // The question ends with a space, so only the link's own 4 pt
        // padding is needed to match the 8 pt gap in Figma.
        AppTextLink(
          label: actionLabel,
          onTap: onAction,
          style: AppTextStyles.headline,
          horizontalPadding: AppSpacing.xs,
        ),
      ],
    );
  }
}
