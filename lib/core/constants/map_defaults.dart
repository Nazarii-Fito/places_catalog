import 'package:latlong2/latlong.dart';

/// Where the location picker opens when nothing is known about the place
/// (a new place, no address to look up): the centre of Lviv.
abstract final class MapDefaults {
  static const LatLng center = LatLng(49.8397, 24.0297);
  static const double zoom = 15;

  /// Zoom used after a search result or "recenter" so the street is visible.
  static const double focusZoom = 17;

  /// Zoom of the small non-interactive map on Place Details.
  static const double previewZoom = 15;
}
