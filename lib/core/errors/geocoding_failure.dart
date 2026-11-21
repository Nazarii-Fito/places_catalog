import '../constants/app_strings.dart';

enum GeocodingFailureType {
  /// No connection or the host cannot be reached.
  network,

  /// The server did not answer in time.
  timeout,

  /// The server answered with an error (4xx/5xx, e.g. rate limiting).
  server,
}

/// A REST (Nominatim) request failed. `DioException`s are translated into
/// this so the Cubit and UI never import `dio`.
class GeocodingFailure implements Exception {
  const GeocodingFailure(this.type, {this.statusCode});

  final GeocodingFailureType type;
  final int? statusCode;

  String get message => switch (type) {
    GeocodingFailureType.network => AppStrings.errorOffline,
    GeocodingFailureType.timeout => AppStrings.errorSearchTimeout,
    GeocodingFailureType.server => AppStrings.errorSearchServer,
  };

  @override
  String toString() => 'GeocodingFailure($type, $statusCode)';
}
