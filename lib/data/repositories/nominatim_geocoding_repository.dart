import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/geocoding_failure.dart';
import '../models/geocoding_result.dart';
import 'geocoding_repository.dart';

/// [GeocodingRepository] on the public Nominatim REST API (OpenStreetMap),
/// called with `dio`:
///
/// * `GET /search?q=…&format=jsonv2&addressdetails=1&limit=5`
/// * `GET /reverse?lat=…&lon=…&format=jsonv2&addressdetails=1`
///
/// Nominatim's usage policy is followed on purpose: an identifying
/// `User-Agent` (no personal data in it), at most one request per second
/// (requests are spaced out here), results cached in memory so the same
/// question is never asked twice, and the language limited to the app's.
class NominatimGeocodingRepository implements GeocodingRepository {
  NominatimGeocodingRepository({
    Dio? dio,
    this.languageCode = 'en',
    this.minInterval = const Duration(seconds: 1),
  }) : _dio = dio ?? _defaultDio();

  /// Sent as `Accept-Language`, so addresses come back in this language.
  final String languageCode;

  /// The smallest gap between two requests (policy: 1 per second).
  final Duration minInterval;

  final Dio _dio;

  static const String baseUrl = 'https://nominatim.openstreetmap.org';

  /// Identifies the app to the operators of Nominatim.
  static const String userAgent = 'PlacesCatalog/1.0 (student lab project)';

  static const int _cacheLimit = 30;
  final Map<String, Object?> _cache = {};
  DateTime? _lastRequest;

  static Dio _defaultDio() {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'User-Agent': userAgent},
      ),
    );
    // Request logging is a debugging aid only; never in release builds.
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(requestHeader: false));
    }
    return dio;
  }

  @override
  Future<List<GeocodingResult>> search(String query) async {
    final String q = query.trim();
    if (q.isEmpty) return const [];
    final Object? data = await _get('search:${q.toLowerCase()}', '/search', {
      'q': q,
      'format': 'jsonv2',
      'addressdetails': 1,
      'limit': 5,
    });
    return [
      for (final Object? item in data as List<Object?>? ?? const [])
        ?_parse(item),
    ];
  }

  @override
  Future<GeocodingResult?> reverse(double latitude, double longitude) async {
    // A cache key rounded to ~1 m: nearly the same point is the same answer.
    final String key =
        'reverse:${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
    final Object? data = await _get(key, '/reverse', {
      'lat': latitude,
      'lon': longitude,
      'format': 'jsonv2',
      'addressdetails': 1,
    });
    // "Nothing here" is a normal 200 answer: {"error": "Unable to geocode"}.
    if (data is! Map<String, Object?> || data.containsKey('error')) return null;
    return _parse(data);
  }

  GeocodingResult? _parse(Object? item) {
    if (item is! Map<String, Object?>) return null;
    try {
      return GeocodingResult.fromJson(item);
    } on FormatException {
      return null; // one bad entry must not hide the others
    }
  }

  Future<Object?> _get(
    String cacheKey,
    String path,
    Map<String, Object?> query,
  ) async {
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];
    await _respectRateLimit();
    try {
      final Response<Object?> response = await _dio.get<Object?>(
        path,
        queryParameters: query,
        options: Options(headers: {'Accept-Language': languageCode}),
      );
      final Object? data = response.data;
      if (_cache.length >= _cacheLimit) _cache.remove(_cache.keys.first);
      return _cache[cacheKey] = data;
    } on DioException catch (error) {
      throw _toFailure(error);
    }
  }

  /// Waits until [minInterval] has passed since the previous request.
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
      case DioExceptionType.transformTimeout:
      case DioExceptionType.receiveTimeout:
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
