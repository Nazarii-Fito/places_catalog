import 'package:flutter/widgets.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../data/models/review.dart';

/// Overall rating badge + per-criterion ratings of a [Review].
///
/// Criteria are optional (`double?`): a missing one is shown as
/// "Not rated" — null safety makes that case explicit in the code.
class RatingSummaryCard extends StatelessWidget {
  const RatingSummaryCard({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final List<(String, String, double?)> criteria = [
      (AppAssets.iconDetailsFood, AppStrings.criterionFood, review.foodRating),
      (
        AppAssets.iconDetailsService,
        AppStrings.criterionService,
        review.serviceRating,
      ),
      (
        AppAssets.iconDetailsAtmosphere,
        AppStrings.criterionAtmosphere,
        review.atmosphereRating,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 54.17,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.star,
                  borderRadius: AppRadii.mdAll,
                  boxShadow: AppShadows.subtle,
                ),
                child: Text(
                  review.overallRating.toStringAsFixed(1),
                  style: AppTextStyles.ratingBadge,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.yourPersonalRating,
                    style: AppTextStyles.footnoteMedium.copyWith(
                      height: 16 / 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RatingStars(
                    rating: review.overallRating,
                    starSize: 15,
                    spacing: AppSpacing.xxs,
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
              height: 0.5,
              child: ColoredBox(color: AppColors.divider),
            ),
          ),
          Column(
            spacing: 10,
            children: criteria
                .map(
                  ((String, String, double?) c) =>
                      _CriterionRow(icon: c.$1, label: c.$2, rating: c.$3),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({
    required this.icon,
    required this.label,
    required this.rating,
  });

  final String icon;
  final String label;
  final double? rating;

  @override
  Widget build(BuildContext context) {
    final double? value = rating;
    return Row(
      children: [
        SizedBox(width: 14.667, child: Center(child: AppSvgIcon(icon))),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTextStyles.footnoteMedium)),
        if (value == null)
          Text(
            AppStrings.notRated,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          )
        else ...[
          RatingStars(rating: value, starSize: 11.667),
          const SizedBox(width: AppSpacing.s),
          Text(
            value.toStringAsFixed(1) + AppStrings.outOfFive,
            style: AppTextStyles.captionSemibold,
          ),
        ],
      ],
    );
  }
}
