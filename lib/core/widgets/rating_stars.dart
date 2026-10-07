import 'package:flutter/widgets.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import 'app_svg_icon.dart';

/// Kind of a single star glyph.
enum StarFill { full, half, empty }

/// Five orange stars for a 1–5 rating (half stars supported).
///
/// The list of glyphs is computed from [rating] and turned into widgets
/// with `.map(...)` — the UI is a pure function of the input value.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating});

  final double rating;

  /// Rounding that matches the design: 4.9 → ★★★★★, 4.8 / 4.7 → ★★★★½.
  static List<StarFill> starsFor(double rating) {
    final int whole = rating.floor();
    final double fraction = rating - whole;
    return List<StarFill>.generate(5, (int i) {
      if (i < whole) return StarFill.full;
      if (i == whole && fraction >= 0.85) return StarFill.full;
      if (i == whole && fraction >= 0.25) return StarFill.half;
      return StarFill.empty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: starsFor(rating)
          .map(
            (StarFill fill) => switch (fill) {
              StarFill.full => const AppSvgIcon(AppAssets.iconStar),
              StarFill.half => const AppSvgIcon(AppAssets.iconStarHalf),
              StarFill.empty => const AppSvgIcon(
                AppAssets.iconStar,
                color: AppColors.outlineVariant,
              ),
            },
          )
          .toList(),
    );
  }
}
