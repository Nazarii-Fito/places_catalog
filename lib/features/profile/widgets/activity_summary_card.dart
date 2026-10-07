import 'package:flutter/widgets.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../data/models/user.dart';

/// "Archived Catalog — Total Visited Places 42" card with four stat tiles.
class ActivitySummaryCard extends StatelessWidget {
  const ActivitySummaryCard({super.key, required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    // Data for the tiles as a list of records → mapped to widgets below.
    final List<(String, int, String)> tiles = [
      (AppAssets.iconCup, stats.cafes, AppStrings.statCafes),
      (AppAssets.iconForkKnife, stats.dining, AppStrings.statDining),
      (AppAssets.iconMuseum, stats.museums, AppStrings.statMuseums),
      (AppAssets.iconHeartStat, stats.favorites, AppStrings.statFavorites),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.mdAll,
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const AppSvgIcon(AppAssets.iconBookmarkStat),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.archivedCatalog,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Text(
                      AppStrings.totalVisitedPlaces,
                      style: AppTextStyles.headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${stats.totalVisitedPlaces}',
                style: AppTextStyles.largeTitle.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m + AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.sm,
            children: tiles
                .map(
                  ((String, int, String) t) => Expanded(
                    child: StatTile(icon: t.$1, value: t.$2, label: t.$3),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
