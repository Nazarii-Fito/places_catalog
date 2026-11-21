import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../data/models/place_category.dart';

/// The icon that stands for a kind of venue on the map and in result lists.
IconData venueIcon(PlaceCategory category) => switch (category) {
  PlaceCategory.cafe => Icons.local_cafe,
  PlaceCategory.restaurant => Icons.restaurant,
  PlaceCategory.bar => Icons.local_bar,
  PlaceCategory.pub => Icons.sports_bar,
  PlaceCategory.fastFood => Icons.fastfood,
  PlaceCategory.bakery => Icons.bakery_dining,
  PlaceCategory.museum => Icons.museum,
  PlaceCategory.hotel => Icons.hotel,
};

/// A small round marker for a venue on the picker map. The chosen venue is
/// filled with the primary colour so it stands out.
class VenueMarker extends StatelessWidget {
  const VenueMarker({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
    required this.label,
  });

  final PlaceCategory category;
  final bool selected;
  final VoidCallback onTap;

  /// The venue's name, for screen readers (and tests).
  final String label;

  static const double size = 30;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: AppShadows.marker,
          ),
          child: Icon(
            venueIcon(category),
            size: 16,
            color: selected ? AppColors.surface : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
