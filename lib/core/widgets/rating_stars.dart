import 'package:flutter/widgets.dart';

import '../constants/app_assets.dart';
import 'app_svg_icon.dart';

/// Kind of a single star glyph.
enum StarFill { full, half, empty }

/// Five orange stars for a 1–5 rating (half stars supported).
///
/// The list of glyphs is computed from [rating] and turned into widgets
/// with `.map(...)` — the UI is a pure function of the input value.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.starSize = 13.333,
    this.spacing = 0,
  });

  final double rating;

  /// Width of one star (height keeps the Figma 20:19 ratio).
  final double starSize;
  final double spacing;

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
    final double height = starSize * 0.95;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: spacing,
      children: starsFor(rating)
          .map(
            (StarFill fill) => AppSvgIcon(
              switch (fill) {
                StarFill.full => AppAssets.iconStar,
                StarFill.half => AppAssets.iconStarHalf,
                StarFill.empty => AppAssets.iconStarEmpty,
              },
              width: starSize,
              height: height,
            ),
          )
          .toList(),
    );
  }
}
