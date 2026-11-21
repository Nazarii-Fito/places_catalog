import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/core/errors/geocoding_failure.dart';
import 'package:places_catalog/data/models/geocoding_result.dart';
import 'package:places_catalog/data/models/place_category.dart';
import 'package:places_catalog/data/repositories/overpass_venues_repository.dart';
import 'package:places_catalog/data/repositories/venues_repository.dart';
import 'package:places_catalog/data/services/location_service.dart';

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

const String _overpassBody = '''
{"elements": [
  {"type": "node", "id": 1, "lat": 49.8421, "lon": 24.0318,
   "tags": {"amenity": "cafe", "name": "Coffeeshop", "addr:street": "Rynok Sq", "addr:housenumber": "5", "addr:city": "Lviv"}},
  {"type": "way", "id": 2, "center": {"lat": 49.84, "lon": 24.03},
   "tags": {"tourism": "museum", "name": "City Museum"}},
  {"type": "node", "id": 3, "lat": 49.8, "lon": 24.0,
   "tags": {"shop": "bakery", "name": "Bread House"}},
  {"type": "node", "id": 4, "lat": 49.8, "lon": 24.1,
   "tags": {"amenity": "cafe"}},
  {"type": "node", "id": 5, "lat": 49.8, "lon": 24.2,
   "tags": {"amenity": "bench", "name": "A Bench"}},
  {"type": "node", "id": 6, "lat": 49.8421, "lon": 24.0318,
   "tags": {"amenity": "cafe", "name": "Coffeeshop"}}
]}
''';

OverpassVenuesRepository _repo(_FakeAdapter adapter) =>
    OverpassVenuesRepository(
      dio: Dio(BaseOptions(baseUrl: OverpassVenuesRepository.baseUrl))
        ..httpClientAdapter = adapter,
      minInterval: Duration.zero,
    );

void main() {
  group('Overpass parsing', () {
    test('keeps named venues of supported kinds, maps categories', () {
      final List<GeocodingResult> out = OverpassVenuesRepository.parse({
        'elements': [
          {
            'lat': 49.84,
            'lon': 24.03,
            'tags': {'amenity': 'fast_food', 'name': 'Burger'},
          },
          {
            'center': {'lat': 1.0, 'lon': 2.0},
            'tags': {'tourism': 'hotel', 'name': 'Grand'},
          },
          {
            'lat': 1.0,
            'lon': 2.0,
            'tags': {'amenity': 'pub', 'name': 'The Pub'},
          },
        ],
      });
      expect(out.map((GeocodingResult v) => v.category), [
        PlaceCategory.fastFood,
        PlaceCategory.hotel,
        PlaceCategory.pub,
      ]);
      expect(out[1].latitude, 1.0); // from `center` (a way)
    });

    test('skips unnamed, unsupported and duplicate entries', () {
      final List<GeocodingResult> out = OverpassVenuesRepository.parse(
        _decode(_overpassBody),
      );
      expect(out.map((GeocodingResult v) => v.title), [
        'Coffeeshop',
        'City Museum',
        'Bread House',
      ]);
    });

    test('builds a readable address from the tags that exist', () {
      final List<GeocodingResult> out = OverpassVenuesRepository.parse(
        _decode(_overpassBody),
      );
      expect(out.first.displayName, 'Coffeeshop, Rynok Sq 5, Lviv');
      expect(out[1].displayName, 'City Museum'); // no address tags
    });

    test('garbage input gives an empty list', () {
      expect(OverpassVenuesRepository.parse(null), isEmpty);
      expect(OverpassVenuesRepository.parse('x'), isEmpty);
      expect(OverpassVenuesRepository.parse({'elements': 5}), isEmpty);
    });
  });

  group('Overpass queries', () {
    test('nearby: only named venues inside the box', () {
      final String q = OverpassVenuesRepository.nearbyQuery(
        const GeoBounds(south: 1, west: 2, north: 3, east: 4),
      );
      expect(q, contains('(1.0,2.0,3.0,4.0)'));
      expect(q, contains('["name"]'));
      expect(q, contains('cafe|restaurant|bar|pub|fast_food'));
      expect(q, contains('"bakery"'));
      expect(q, contains('museum|hotel'));
      expect(q, contains('out center'));
    });

    test('name search escapes regex characters typed by the user', () {
      expect(OverpassVenuesRepository.escapeRegex('a.b(c)"d'), r'a\.b\(c\)\"d');
      final String q = OverpassVenuesRepository.nameQuery('St.k', 49.8, 24.0);
      expect(q, contains(r'["name"~"St\.k",i]'));
    });
  });

  group('OverpassVenuesRepository', () {
    test('nearby: one request, parsed result, cached by area', () async {
      final _FakeAdapter adapter = _FakeAdapter((_) => _json(_overpassBody));
      final OverpassVenuesRepository repo = _repo(adapter);
      const GeoBounds area = GeoBounds(
        south: 49.83,
        west: 24.02,
        north: 49.85,
        east: 24.04,
      );
      final List<GeocodingResult> first = await repo.nearby(area);
      await repo.nearby(area);
      expect(first, hasLength(3));
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.path, '/api/interpreter');
      expect(
        adapter.requests.single.headers['User-Agent'],
        'PlacesCatalog/1.0 (student lab project)',
      );
    });

    test('a very short name query makes no request', () async {
      final _FakeAdapter adapter = _FakeAdapter((_) => _json('{}'));
      expect(
        await _repo(adapter).searchByName('a', latitude: 1, longitude: 2),
        isEmpty,
      );
      expect(adapter.requests, isEmpty);
    });

    test('errors become typed failures', () async {
      final _FakeAdapter busy = _FakeAdapter((_) => _json('{}', 429));
      await expectLater(
        _repo(busy)
            .nearby(const GeoBounds(south: 0, west: 0, north: 1, east: 1)),
        throwsA(
          isA<GeocodingFailure>().having(
            (GeocodingFailure f) => f.type,
            'type',
            GeocodingFailureType.server,
          ),
        ),
      );
      final _FakeAdapter slow = _FakeAdapter(
        (RequestOptions o) => throw DioException(
          requestOptions: o,
          type: DioExceptionType.receiveTimeout,
        ),
      );
      await expectLater(
        _repo(slow)
            .nearby(const GeoBounds(south: 5, west: 5, north: 6, east: 6)),
        throwsA(isA<GeocodingFailure>()),
      );
    });
  });

  group('LocationFailure', () {
    test('every type has a message for the user', () {
      for (final LocationFailureType t in LocationFailureType.values) {
        expect(LocationFailure(t).message, isNotEmpty);
      }
    });

    test('GeoBounds.around makes a box around the point', () {
      final GeoBounds b = GeoBounds.around(10, 20);
      expect(b.south, lessThan(10));
      expect(b.north, greaterThan(10));
      expect(b.west, lessThan(20));
      expect(b.east, greaterThan(20));
    });
  });
}

Object? _decode(String s) => jsonDecode(s);
