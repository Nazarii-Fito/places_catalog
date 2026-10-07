import 'package:flutter/foundation.dart';

import '../../data/models/place.dart';

/// Arguments of the `AppRoutes.placeDetails` route.
///
/// The catalog list lives in `MainShell`, so the details screen reports
/// changes back through these callbacks instead of owning the data.
class PlaceDetailsArgs {
  const PlaceDetailsArgs({
    required this.place,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  final Place place;
  final ValueChanged<Place> onToggleFavorite;
  final ValueChanged<Place> onDelete;
}
