import 'dart:async';
import 'dart:convert';

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
    this.endpoints = defaultEndpoints,
    this.hedgeDelay = const Duration(seconds: 3),
  }) : _dio = dio ?? _defaultDio();

  final Dio _dio;
  final Duration minInterval;

  /// Public Overpass servers, tried in order. They are shared and
  /// frequently "at capacity" (HTTP 502/504/429), so one failure must not
  /// leave the map empty: the next server is asked.
  final List<String> endpoints;

  /// How long to wait for a server before also asking the next one.
  final Duration hedgeDelay;

  static const String baseUrl = 'https://overpass-api.de';
  static const List<String> defaultEndpoints = [
    'https://overpass.private.coffee/api/interpreter',
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.fr/api/interpreter',
  ];

  static const int _cacheLimit = 20;
  final Map<String, List<GeocodingResult>> _cache = {};
  DateTime? _lastRequest;

  static Dio _defaultDio() {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 15),
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
    final List<GeocodingResult> venues = await _fetchHedged(query);
    if (_cache.length >= _cacheLimit) _cache.remove(_cache.keys.first);
    return _cache[cacheKey] = venues;
  }

  /// Asks the servers *staggered*: the first at once, the next after
  /// [hedgeDelay] (or immediately if the one before failed), and so on. The
  /// first good answer wins and the others are cancelled. Shared Overpass
  /// servers are often slow or busy; waiting for each to time out in turn
  /// took tens of seconds, this takes about as long as the fastest server.
  Future<List<GeocodingResult>> _fetchHedged(String query) {
    final Completer<List<GeocodingResult>> done = Completer();
    final CancelToken cancel = CancelToken();
    final List<Timer> timers = [];
    int started = 0;
    int failed = 0;

    void finish() {
      for (final Timer t in timers) {
        t.cancel();
      }
      cancel.cancel();
    }

    late void Function(GeocodingFailure) onFailure;
    late void Function() startNext;

    Future<void> attempt(String endpoint) async {
      try {
        final Response<Object?> response = await _dio.get<Object?>(
          endpoint,
          queryParameters: {'data': query},
          cancelToken: cancel,
          // Sent with every request (not only via the default client), so
          // the operators can always tell who is calling.
          options: Options(
            headers: {'User-Agent': NominatimGeocodingRepository.userAgent},
          ),
        );
        if (done.isCompleted) return;
        done.complete(parse(_asJson(response.data)));
        finish();
      } on DioException catch (error) {
        if (CancelToken.isCancel(error) || done.isCompleted) return;
        onFailure(_toFailure(error));
      } on FormatException {
        if (done.isCompleted) return;
        onFailure(const GeocodingFailure(GeocodingFailureType.server));
      }
    }

    startNext = () {
      if (done.isCompleted || started >= endpoints.length) return;
      attempt(endpoints[started++]);
    };

    // A failure starts the next server at once; when all failed, give up.
    onFailure = (GeocodingFailure failure) {
      failed++;
      if (failed >= endpoints.length) {
        if (!done.isCompleted) done.completeError(failure);
      } else if (failed >= started) {
        startNext();
      }
    };

    startNext();
    for (int i = 1; i < endpoints.length; i++) {
      timers.add(Timer(hedgeDelay * i, startNext));
    }
    return done.future;
  }

  /// A busy server may answer `text/plain`, which Dio leaves as a string.
  static Object? _asJson(Object? data) =>
      data is String ? jsonDecode(data) : data;

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
