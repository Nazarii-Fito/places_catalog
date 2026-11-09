import 'package:flutter/widgets.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'secondary_button.dart';

/// Centered load failure: [message] and a Retry button, in the same visual
/// language as `EmptyState`.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 48,
        horizontal: AppSpacing.screen,
      ),
      child: Column(
        children: [
          Text(
            message,
            style: AppTextStyles.headline.copyWith(
              color: AppColors.destructive,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.l),
          SecondaryButton(label: AppStrings.retry, onPressed: onRetry),
        ],
      ),
    );
  }
}
