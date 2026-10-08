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
    required this.onUpdate,
    required this.onDelete,
  });

  final Place place;
  final ValueChanged<Place> onToggleFavorite;

  /// Called with the edited copy after notes or tags change.
  final ValueChanged<Place> onUpdate;
  final ValueChanged<Place> onDelete;
}
