import 'package:flutter/cupertino.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Red inline message for server errors (failed log-in, sign-up, …),
/// shown above the submit button. Validation errors stay under fields.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.m - 2,
        ),
        decoration: const BoxDecoration(
          color: AppColors.destructiveContainer,
          borderRadius: AppRadii.mdAll,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                CupertinoIcons.exclamationmark_circle_fill,
                size: 16,
                color: AppColors.destructive,
              ),
            ),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.footnoteMedium.copyWith(
                  color: AppColors.destructive,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
