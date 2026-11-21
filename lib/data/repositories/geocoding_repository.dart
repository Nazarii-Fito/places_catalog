import '../models/geocoding_result.dart';

/// Address search and reverse geocoding. An interface so the location picker
/// does not know which REST service answers (Nominatim today).
abstract interface class GeocodingRepository {
  /// Places matching [query] (best first); empty when nothing is found.
  /// Throws `GeocodingFailure`.
  Future<List<GeocodingResult>> search(String query);

  /// The place at the point, or `null` when the point has no address (open
  /// water, desert). Throws `GeocodingFailure`.
  Future<GeocodingResult?> reverse(double latitude, double longitude);
}

/// Scripted geocoder for tests and the screenshot mode: no network.
class FakeGeocodingRepository implements GeocodingRepository {
  FakeGeocodingRepository({this.results, this.failure});

  /// What `search` returns; defaults to one fixed match.
  List<GeocodingResult>? results;

  /// Thrown by the next call (and every one after, until cleared).
  Object? failure;

  final List<String> searches = [];
  final List<(double, double)> reverses = [];

  @override
  Future<List<GeocodingResult>> search(String query) async {
    searches.add(query);
    final Object? error = failure;
    if (error != null) throw error;
    return results ??
        const [
          GeocodingResult(
            displayName: 'Fake Cafe, 1 Test Street, Testville',
            title: 'Fake Cafe',
            latitude: 50.4501,
            longitude: 30.5234,
          ),
        ];
  }

  @override
  Future<GeocodingResult?> reverse(double latitude, double longitude) async {
    reverses.add((latitude, longitude));
    final Object? error = failure;
    if (error != null) throw error;
    return GeocodingResult(
      displayName: '1 Test Street, Testville, Testland',
      title: '1 Test Street',
      latitude: latitude,
      longitude: longitude,
    );
  }
}
