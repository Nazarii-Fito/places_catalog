import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/geocoding_failure.dart';
import '../models/geocoding_result.dart';
import '../models/place_category.dart';
import 'nominatim_geocoding_repository.dart';
import 'venues_repository.dart';

/// [VenuesRepository] on the Overpass API — a free read-only query service
/// over the same OpenStreetMap data the map shows (no key needed).
///
/// OpenStreetMap map *tiles* deliberately carry no shop/cafe icons, so the
/// venues are fetched here and drawn by the app as its own markers.
/// Be a polite client: an identifying `User-Agent`, requests spaced out, and
/// results cached by area.
class OverpassVenuesRepository implements VenuesRepository {
  OverpassVenuesRepository({
    Dio? dio,
    this.minInterval = const Duration(seconds: 1),
  }) : _dio = dio ?? _defaultDio();

  final Dio _dio;
  final Duration minInterval;

  static const String baseUrl = 'https://overpass-api.de';

  static const int _cacheLimit = 20;
  final Map<String, List<GeocodingResult>> _cache = {};
  DateTime? _lastRequest;

  static Dio _defaultDio() {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'User-Agent': NominatimGeocodingRepository.userAgent},
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestHeader: false, responseBody: false),
      );
    }
    return dio;
  }

  /// OpenStreetMap tag → the app's category.
  static const Map<String, PlaceCategory> _amenity = {
    'cafe': PlaceCategory.cafe,
    'restaurant': PlaceCategory.restaurant,
    'bar': PlaceCategory.bar,
    'pub': PlaceCategory.pub,
    'fast_food': PlaceCategory.fastFood,
  };

  /// The part of an Overpass query that selects the supported venue kinds.
  /// [nameFilter] (already escaped) restricts to venues whose name matches.
  static String venueSelectors(String area, {String nameFilter = ''}) =>
      'nwr["amenity"~"^(cafe|restaurant|bar|pub|fast_food)\$"]$nameFilter$area;'
      'nwr["shop"="bakery"]$nameFilter$area;'
      'nwr["tourism"~"^(museum|hotel)\$"]$nameFilter$area;';

  /// The full query for [nearby]. Public for tests.
  static String nearbyQuery(GeoBounds b) {
    final String area = '(${b.south},${b.west},${b.north},${b.east})';
    return '[out:json][timeout:15];(${venueSelectors(area, nameFilter: '["name"]')});'
        'out center 60;';
  }

  /// The full query for [searchByName]. Public for tests.
  static String nameQuery(String query, double lat, double lon) {
    final GeoBounds b = GeoBounds.around(lat, lon, 0.15); // ~16 km square
    final String area = '(${b.south},${b.west},${b.north},${b.east})';
    final String filter = '["name"~"${escapeRegex(query)}",i]';
    return '[out:json][timeout:15];(${venueSelectors(area, nameFilter: filter)});'
        'out center 10;';
  }

  /// Makes user text safe inside an Overpass regular expression string.
  static String escapeRegex(String text) => text.replaceAllMapped(
    RegExp(r'[\\.^$*+?()[\]{}|"]'),
    (Match m) => '\\${m[0]}',
  );

  @override
  Future<List<GeocodingResult>> nearby(GeoBounds bounds) {
    // ~100 m rounding: moving the map a little reuses the answer.
    final String key =
        'near:${bounds.south.toStringAsFixed(3)},${bounds.west.toStringAsFixed(3)},'
        '${bounds.north.toStringAsFixed(3)},${bounds.east.toStringAsFixed(3)}';
    return _run(key, nearbyQuery(bounds));
  }

  @override
  Future<List<GeocodingResult>> searchByName(
    String query, {
    required double latitude,
    required double longitude,
  }) {
    final String q = query.trim();
    if (q.length < 2) return Future.value(const []);
    final String key =
        'name:${q.toLowerCase()}:${latitude.toStringAsFixed(1)},${longitude.toStringAsFixed(1)}';
    return _run(key, nameQuery(q, latitude, longitude));
  }

  Future<List<GeocodingResult>> _run(String cacheKey, String query) async {
    final List<GeocodingResult>? cached = _cache[cacheKey];
    if (cached != null) return cached;
    await _respectRateLimit();
    try {
      final Response<Object?> response = await _dio.get<Object?>(
        '/api/interpreter',
        queryParameters: {'data': query},
        // Sent with every request (not only via the default client), so the
        // operators can always tell who is calling.
        options: Options(
          headers: {'User-Agent': NominatimGeocodingRepository.userAgent},
        ),
      );
      final List<GeocodingResult> venues = parse(response.data);
      if (_cache.length >= _cacheLimit) _cache.remove(_cache.keys.first);
      return _cache[cacheKey] = venues;
    } on DioException catch (error) {
      throw _toFailure(error);
    }
  }

  /// Turns an Overpass JSON answer into venues (named ones only). Public for
  /// tests.
  static List<GeocodingResult> parse(Object? body) {
    if (body is! Map<String, Object?>) return const [];
    final List<GeocodingResult> out = [];
    final Set<String> seen = {};
    final Object? elements = body['elements'];
    if (elements is! List<Object?>) return const [];
    for (final Object? e in elements) {
      if (e is! Map<String, Object?>) continue;
      final Map<String, Object?>? tags = e['tags'] as Map<String, Object?>?;
      final String name = (tags?['name'] as String? ?? '').trim();
      final PlaceCategory? category = _categoryOf(tags);
      // Ways and relations carry their middle in `center`.
      final Map<String, Object?>? centre = e['center'] as Map<String, Object?>?;
      final double? lat = ((e['lat'] ?? centre?['lat']) as num?)?.toDouble();
      final double? lon = ((e['lon'] ?? centre?['lon']) as num?)?.toDouble();
      if (name.isEmpty || category == null || lat == null || lon == null) {
        continue;
      }
      if (!seen.add(
        '$name@${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}',
      )) {
        continue;
      }
      out.add(
        GeocodingResult(
          displayName: _address(name, tags!),
          title: name,
          latitude: lat,
          longitude: lon,
          category: category,
        ),
      );
    }
    return out;
  }

  static PlaceCategory? _categoryOf(Map<String, Object?>? tags) {
    if (tags == null) return null;
    final PlaceCategory? byAmenity = _amenity[tags['amenity']];
    if (byAmenity != null) return byAmenity;
    if (tags['shop'] == 'bakery') return PlaceCategory.bakery;
    return switch (tags['tourism']) {
      'museum' => PlaceCategory.museum,
      'hotel' => PlaceCategory.hotel,
      _ => null,
    };
  }

  /// "Name, Street 5, City" from whatever address tags exist.
  static String _address(String name, Map<String, Object?> tags) {
    final String street = (tags['addr:street'] as String? ?? '').trim();
    final String number = (tags['addr:housenumber'] as String? ?? '').trim();
    final String city = (tags['addr:city'] as String? ?? '').trim();
    final String line = [
      street,
      number,
    ].where((String s) => s.isNotEmpty).join(' ');
    return [name, line, city].where((String s) => s.isNotEmpty).join(', ');
  }

  Future<void> _respectRateLimit() async {
    final DateTime? last = _lastRequest;
    if (last != null) {
      final Duration wait = minInterval - DateTime.now().difference(last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    _lastRequest = DateTime.now();
  }

  GeocodingFailure _toFailure(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const GeocodingFailure(GeocodingFailureType.timeout);
      case DioExceptionType.badResponse:
        return GeocodingFailure(
          GeocodingFailureType.server,
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const GeocodingFailure(GeocodingFailureType.network);
    }
  }
}
