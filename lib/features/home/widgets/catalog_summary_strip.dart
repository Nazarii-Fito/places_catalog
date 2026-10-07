import 'package:flutter/widgets.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';

/// "■ 24 recorded spots · Sorted by Recent ⇅" metric strip.
class CatalogSummaryStrip extends StatelessWidget {
  const CatalogSummaryStrip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.mdAll,
      ),
      child: Row(
        children: [
          const AppSvgIcon(AppAssets.iconBookmark),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$count',
                children: [
                  TextSpan(
                    text: AppStrings.recordedSpots,
                    style: AppTextStyles.footnoteMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              style: AppTextStyles.footnoteSemibold,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            AppStrings.sortedByRecent,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          const AppSvgIcon(AppAssets.iconSort),
        ],
      ),
    );
  }
}
