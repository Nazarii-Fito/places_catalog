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

/// Visual variant of a [PlaceCard] — each matches one Figma frame.
enum PlaceCardVariant {
  /// Home: 84 pt thumbnail, five stars, one-line title, centred row.
  home,

  /// Favorites: 88 pt thumbnail, one star + orange value, title wraps to
  /// two lines, content aligned to the top.
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
    final bool isHome = variant == PlaceCardVariant.home;
    final double padding = isHome ? AppSpacing.ml : AppSpacing.m;
    final double heartInset = isHome ? AppSpacing.s : AppSpacing.sm;
    return PressableOpacity(
      onTap: onTap,
      pressedOpacity: 0.8,
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(padding),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.lgAll,
              boxShadow: AppShadows.subtle,
            ),
            child: Row(
              crossAxisAlignment: isHome
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                _Thumbnail(
                  asset: place.coverImage,
                  size: isHome ? AppSizes.placeThumbnail : 88,
                ),
                const SizedBox(width: AppSpacing.ml),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xxl),
                    child: isHome
                        ? _HomeDetails(place: place)
                        : _FavoriteDetails(place: place),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: heartInset,
            right: heartInset,
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
  const _Thumbnail({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.mdAll,
      child: ColoredBox(
        color: AppColors.surfaceContainer,
        child: Image.asset(asset, width: size, height: size, fit: BoxFit.cover),
      ),
    );
  }
}

class _HomeDetails extends StatelessWidget {
  const _HomeDetails({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.name,
          style: AppTextStyles.cardTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        _Subtitle(text: place.subtitle),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            RatingStars(rating: place.rating),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                place.rating.toStringAsFixed(1),
                style: AppTextStyles.footnoteSemibold,
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

class _FavoriteDetails extends StatelessWidget {
  const _FavoriteDetails({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.name,
          style: AppTextStyles.headline,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        _Subtitle(text: place.subtitle),
        const SizedBox(height: AppSpacing.s),
        Row(
          spacing: AppSpacing.s,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.xxs,
              children: [
                const AppSvgIcon(AppAssets.iconStar),
                Text(
                  place.rating.toStringAsFixed(1),
                  style: AppTextStyles.captionSemibold.copyWith(
                    color: AppColors.cafeAccent,
                  ),
                ),
              ],
            ),
            Text(
              '•',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.outlineVariant,
              ),
            ),
            Flexible(
              child: Text(
                AppStrings.visitedPrefix + formatShortDate(place.visitDate),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
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

class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.footnote.copyWith(color: AppColors.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
