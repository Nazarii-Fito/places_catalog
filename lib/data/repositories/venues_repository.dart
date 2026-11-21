import '../models/geocoding_result.dart';
import '../models/place_category.dart';

/// A rectangle on the map, in degrees.
class GeoBounds {
  const GeoBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  /// A square of about `2 × [halfSideDegrees]` around a point (0.004° ≈ 450 m).
  factory GeoBounds.around(
    double latitude,
    double longitude, [
    double halfSideDegrees = 0.004,
  ]) => GeoBounds(
    south: latitude - halfSideDegrees,
    west: longitude - halfSideDegrees,
    north: latitude + halfSideDegrees,
    east: longitude + halfSideDegrees,
  );

  final double south;
  final double west;
  final double north;
  final double east;
}

/// Venues (cafes, restaurants, bars, museums…) from the map data: what is
/// around a spot, and finding one by name. Address search alone cannot do
/// this — a geocoder knows streets, not every coffee shop.
abstract interface class VenuesRepository {
  /// Named venues inside [bounds], at most a few dozen. Throws
  /// `GeocodingFailure`.
  Future<List<GeocodingResult>> nearby(GeoBounds bounds);

  /// Venues whose name contains [query], near a point. Throws
  /// `GeocodingFailure`.
  Future<List<GeocodingResult>> searchByName(
    String query, {
    required double latitude,
    required double longitude,
  });
}

/// Scripted venues for tests and the screenshot mode: no network.
class FakeVenuesRepository implements VenuesRepository {
  FakeVenuesRepository({List<GeocodingResult>? venues, this.failure})
    : venues = venues ?? defaultVenues;

  static const List<GeocodingResult> defaultVenues = [
    GeocodingResult(
      displayName: 'Fake Roasters, 5 Coffee Lane',
      title: 'Fake Roasters',
      latitude: 49.8421,
      longitude: 24.0318,
      category: PlaceCategory.cafe,
    ),
    GeocodingResult(
      displayName: 'Fake Trattoria, 9 Pasta Street',
      title: 'Fake Trattoria',
      latitude: 49.8415,
      longitude: 24.0309,
      category: PlaceCategory.restaurant,
    ),
  ];

  List<GeocodingResult> venues;
  Object? failure;
  final List<GeoBounds> nearbyCalls = [];
  final List<String> nameSearches = [];

  @override
  Future<List<GeocodingResult>> nearby(GeoBounds bounds) async {
    nearbyCalls.add(bounds);
    final Object? error = failure;
    if (error != null) throw error;
    return venues;
  }

  @override
  Future<List<GeocodingResult>> searchByName(
    String query, {
    required double latitude,
    required double longitude,
  }) async {
    nameSearches.add(query);
    final Object? error = failure;
    if (error != null) throw error;
    final String q = query.toLowerCase();
    return [
      for (final GeocodingResult v in venues)
        if (v.title.toLowerCase().contains(q)) v,
    ];
  }
}
