import 'package:flutter/widgets.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';

/// Shown when search + filter leave no places.
class EmptyPlacesView extends StatelessWidget {
  const EmptyPlacesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const AppSvgIcon(
              AppAssets.iconSearch,
              width: 24,
              height: 24,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          const Text(AppStrings.emptyTitle, style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.emptySubtitle,
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
