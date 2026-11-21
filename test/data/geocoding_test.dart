import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/core/errors/geocoding_failure.dart';
import 'package:places_catalog/core/utils/coordinates_formatter.dart';
import 'package:places_catalog/data/models/geocoding_result.dart';
import 'package:places_catalog/data/repositories/nominatim_geocoding_repository.dart';
import 'package:places_catalog/data/services/map_launcher.dart';

/// Answers requests from a script; records them. No network is touched.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final FutureOr<ResponseBody> Function(RequestOptions options) respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, [int status = 200]) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

const String _searchBody = '''
[
  {"lat": "40.7484", "lon": "-73.9857", "name": "Empire State Building",
   "display_name": "Empire State Building, 350, 5th Avenue, New York"},
  {"lat": "40.7580", "lon": "-73.9855",
   "display_name": "Times Square, Manhattan, New York"},
  {"display_name": "broken entry without coordinates"}
]
''';

NominatimGeocodingRepository _repo(
  _FakeAdapter adapter, {
  String language = 'uk',
  Duration interval = Duration.zero,
}) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: NominatimGeocodingRepository.baseUrl,
      headers: {'User-Agent': NominatimGeocodingRepository.userAgent},
    ),
  )..httpClientAdapter = adapter;
  return NominatimGeocodingRepository(
    dio: dio,
    languageCode: language,
    minInterval: interval,
  );
}

void main() {
  group('GeocodingResult', () {
    test('reads string coordinates and picks a title', () {
      final GeocodingResult r = GeocodingResult.fromJson({
        'lat': '40.7484',
        'lon': '-73.9857',
        'display_name': 'Times Square, Manhattan, New York',
      });
      expect(r.latitude, 40.7484);
      expect(r.longitude, -73.9857);
      expect(r.title, 'Times Square'); // first part of the address
    });

    test('prefers the object name; missing coordinates are rejected', () {
      expect(
        GeocodingResult.fromJson({
          'lat': '1',
          'lon': '2',
          'name': 'Cafe X',
          'display_name': 'Cafe X, Street',
        }).title,
        'Cafe X',
      );
      expect(
        () => GeocodingResult.fromJson({'display_name': 'x'}),
        throwsFormatException,
      );
    });
  });

  group('formatCoordinates', () {
    test('uses hemisphere letters', () {
      expect(formatCoordinates(40.7587, -73.9787), '40.7587° N, 73.9787° W');
      expect(formatCoordinates(-33.8688, 151.2093), '33.8688° S, 151.2093° E');
    });
  });

  group('NominatimGeocodingRepository', () {
    test('search: asks the right URL, parses, skips a broken entry', () async {
      final _FakeAdapter adapter = _FakeAdapter((_) => _json(_searchBody));
      final List<GeocodingResult> found = await _repo(adapter)
          .search(' Empire ');
      expect(found, hasLength(2));
      expect(found.first.title, 'Empire State Building');

      final RequestOptions request = adapter.requests.single;
      expect(request.path, '/search');
      expect(request.queryParameters['q'], 'Empire'); // trimmed
      expect(request.queryParameters['format'], 'jsonv2');
      expect(request.queryParameters['addressdetails'], 1);
      expect(request.queryParameters['limit'], 5);
    });

    test(
      'policy headers: identifying User-Agent, app language, no e-mail',
      () async {
        final _FakeAdapter adapter = _FakeAdapter((_) => _json('[]'));
        await _repo(adapter, language: 'uk').search('x');
        final Map<String, dynamic> headers = adapter.requests.single.headers;
        expect(
          headers['User-Agent'],
          'PlacesCatalog/1.0 (student lab project)',
        );
        expect(headers['Accept-Language'], 'uk');
        expect(headers.values.join(), isNot(contains('@')));
      },
    );

    test(
      'an empty query makes no request; no match gives an empty list',
      () async {
        final _FakeAdapter adapter = _FakeAdapter((_) => _json('[]'));
        final NominatimGeocodingRepository repo = _repo(adapter);
        expect(await repo.search('   '), isEmpty);
        expect(adapter.requests, isEmpty);
        expect(await repo.search('nowhere'), isEmpty);
      },
    );

    test(
      'reverse: parses the object; "error" means no address (null)',
      () async {
        final _FakeAdapter adapter = _FakeAdapter(
          (RequestOptions o) => o.queryParameters['lat'] == 0.0
              ? _json('{"error": "Unable to geocode"}')
              : _json(
                  '{"lat": "40.7", "lon": "-73.9", "display_name": "1 Main St, Town"}',
                ),
        );
        final NominatimGeocodingRepository repo = _repo(adapter);
        final GeocodingResult? ok = await repo.reverse(40.7, -73.9);
        expect(ok!.title, '1 Main St');
        expect(adapter.requests.single.path, '/reverse');
        expect(await repo.reverse(0, 0), isNull);
      },
    );

    test('the same question is answered from the cache', () async {
      final _FakeAdapter adapter = _FakeAdapter((_) => _json(_searchBody));
      final NominatimGeocodingRepository repo = _repo(adapter);
      await repo.search('Empire');
      await repo.search('empire'); // same, different case
      expect(adapter.requests, hasLength(1));
    });

    test('requests are spaced by the minimum interval', () async {
      final _FakeAdapter adapter = _FakeAdapter((_) => _json('[]'));
      final NominatimGeocodingRepository repo = _repo(
        adapter,
        interval: const Duration(milliseconds: 120),
      );
      final Stopwatch watch = Stopwatch()..start();
      await repo.search('a');
      await repo.search('b');
      expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(110));
    });

    for (final (int status, GeocodingFailureType type) in [
      (429, GeocodingFailureType.server),
      (500, GeocodingFailureType.server),
      (403, GeocodingFailureType.server),
    ]) {
      test('HTTP $status becomes a server failure with the status', () async {
        final _FakeAdapter adapter = _FakeAdapter(
          (_) => _json('{"error":"x"}', status),
        );
        await expectLater(
          _repo(adapter).search('x'),
          throwsA(
            isA<GeocodingFailure>()
                .having((GeocodingFailure f) => f.type, 'type', type)
                .having((GeocodingFailure f) => f.statusCode, 'status', status),
          ),
        );
      });
    }

    test('a timeout and a lost connection are told apart', () async {
      Future<GeocodingFailureType> failureFor(DioExceptionType type) async {
        final _FakeAdapter adapter = _FakeAdapter(
          (RequestOptions o) =>
              throw DioException(requestOptions: o, type: type),
        );
        try {
          await _repo(adapter).search('x');
        } on GeocodingFailure catch (f) {
          return f.type;
        }
        fail('should throw');
      }

      expect(
        await failureFor(DioExceptionType.receiveTimeout),
        GeocodingFailureType.timeout,
      );
      expect(
        await failureFor(DioExceptionType.connectionTimeout),
        GeocodingFailureType.timeout,
      );
      expect(
        await failureFor(DioExceptionType.connectionError),
        GeocodingFailureType.network,
      );
    });
  });

  group('UrlLauncherMapLauncher.uriFor', () {
    test('Apple Maps on iOS', () {
      final Uri uri = UrlLauncherMapLauncher.uriFor(
        latitude: 40.7,
        longitude: -73.9,
        label: 'Cafe',
        platform: TargetPlatform.iOS,
      );
      expect(uri.host, 'maps.apple.com');
      expect(uri.queryParameters['ll'], '40.7,-73.9');
      expect(uri.queryParameters['q'], 'Cafe');
    });

    test('a geo: link on Android', () {
      final Uri uri = UrlLauncherMapLauncher.uriFor(
        latitude: 40.7,
        longitude: -73.9,
        label: 'Cafe',
        platform: TargetPlatform.android,
      );
      expect(uri.scheme, 'geo');
      expect(uri.path, '40.7,-73.9');
    });
  });
}
