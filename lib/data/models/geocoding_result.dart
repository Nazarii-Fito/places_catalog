import 'place_category.dart';

/// A place found by address search, by looking up a point on the map, or as
/// a venue (cafe, restaurant…) near it.
class GeocodingResult {
  const GeocodingResult({
    required this.displayName,
    required this.title,
    required this.latitude,
    required this.longitude,
    this.category,
  });

  /// Reads one object of Nominatim's `jsonv2` format (`/search` returns a
  /// list of them, `/reverse` a single one). Throws [FormatException] when
  /// the coordinates are missing — Nominatim sends them as *strings*.
  factory GeocodingResult.fromJson(Map<String, Object?> json) {
    final double? lat = double.tryParse('${json['lat']}');
    final double? lon = double.tryParse('${json['lon']}');
    if (lat == null || lon == null) {
      throw const FormatException('Geocoding result without coordinates');
    }
    final String display = (json['display_name'] as String? ?? '').trim();
    final String name = (json['name'] as String? ?? '').trim();
    return GeocodingResult(
      displayName: display,
      // Header of the location card: the object's own name, else the first
      // part of the address ("5 Avenue, Manhattan, …" → "5 Avenue").
      title: name.isNotEmpty ? name : display.split(',').first.trim(),
      latitude: lat,
      longitude: lon,
    );
  }

  /// Full address, e.g. "Empire State Building, 350, 5th Avenue, Midtown…".
  final String displayName;
  final String title;
  final double latitude;
  final double longitude;

  /// Set for venues (a cafe, a museum…): what kind of place it is, so the form
  /// can fill in the category. `null` for plain addresses.
  final PlaceCategory? category;

  bool get isVenue => category != null;
}

/// What the location picker hands back to the place form: a text address
/// plus the point (FR4: "saves the text address and the GPS coordinates").
class PickedLocation {
  const PickedLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.name,
    this.category,
  });

  final String address;
  final double latitude;
  final double longitude;

  /// Only when the user chose a venue on the map: its name and kind. The form
  /// uses them to pre-fill the place name and category.
  final String? name;
  final PlaceCategory? category;
}

/// What the form tells the location picker when it opens: the place's current
/// address, and its point if it has one (old records may not).
class LocationPickerArgs {
  const LocationPickerArgs({
    required this.address,
    this.latitude,
    this.longitude,
  });

  final String address;
  final double? latitude;
  final double? longitude;

  bool get hasPoint => latitude != null && longitude != null;
}
