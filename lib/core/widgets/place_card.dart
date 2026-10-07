import 'package:flutter/widgets.dart';

import '../../data/models/place.dart';
import '../constants/app_assets.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/date_formatter.dart';
import 'app_svg_icon.dart';
import 'pressable_opacity.dart';
import 'rating_stars.dart';

/// How the rating is presented inside a [PlaceCard].
enum PlaceCardVariant {
  /// Five stars + value, one-line title (Home).
  home,

  /// One star + orange value, title may wrap to two lines (Favorites).
  favorites,
}

/// White card of a visited place: thumbnail, name, subtitle, rating,
/// visit date and a favourite heart.
///
/// Layout: a [Stack] puts the 44×44 heart button over the top-right corner
/// of a [Row] (thumbnail + [Column] of texts).
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    required this.onFavoriteToggle,
    this.onTap,
    this.variant = PlaceCardVariant.home,
  });

  final Place place;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onTap;
  final PlaceCardVariant variant;

  @override
  Widget build(BuildContext context) {
    return PressableOpacity(
      onTap: onTap,
      pressedOpacity: 0.8,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.ml),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.lgAll,
              boxShadow: AppShadows.subtle,
            ),
            child: Row(
              children: [
                _Thumbnail(asset: place.coverImage),
                const SizedBox(width: AppSpacing.ml),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xxl),
                    child: _Details(place: place, variant: variant),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: AppSpacing.s,
            right: AppSpacing.s,
            child: _FavoriteButton(
              isFavorite: place.isFavorite,
              onTap: onFavoriteToggle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.mdAll,
      child: ColoredBox(
        color: AppColors.surfaceContainer,
        child: Image.asset(
          asset,
          width: AppSizes.placeThumbnail,
          height: AppSizes.placeThumbnail,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.place, required this.variant});

  final Place place;
  final PlaceCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final bool isHome = variant == PlaceCardVariant.home;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.name,
          style: AppTextStyles.cardTitle,
          maxLines: isHome ? 1 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          place.subtitle,
          style: AppTextStyles.footnote.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            if (isHome)
              RatingStars(rating: place.rating)
            else
              const AppSvgIcon(AppAssets.iconStar),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                place.rating.toStringAsFixed(1),
                style: AppTextStyles.footnoteSemibold.copyWith(
                  color: isHome ? AppColors.textPrimary : AppColors.cafeAccent,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const _Dot(),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                AppStrings.visitedPrefix + formatShortDate(place.visitDate),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.outlineVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: isFavorite,
      label: AppStrings.toggleFavorite,
      child: PressableOpacity(
        onTap: onTap,
        child: SizedBox.square(
          dimension: AppSpacing.minTapTarget,
          child: Center(
            child: AppSvgIcon(
              isFavorite
                  ? AppAssets.iconHeartFilled
                  : AppAssets.iconHeartOutline,
            ),
          ),
        ),
      ),
    );
  }
}
