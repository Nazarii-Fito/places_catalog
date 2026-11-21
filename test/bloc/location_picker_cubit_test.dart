import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:places_catalog/core/errors/geocoding_failure.dart';
import 'package:places_catalog/data/models/geocoding_result.dart';
import 'package:places_catalog/data/models/place_category.dart';
import 'package:places_catalog/data/repositories/geocoding_repository.dart';
import 'package:places_catalog/data/repositories/venues_repository.dart';
import 'package:places_catalog/data/services/location_service.dart';
import 'package:places_catalog/features/places/bloc/location_picker_cubit.dart';

const LatLng _start = LatLng(49.84, 24.03);

const GeocodingResult _a = GeocodingResult(
  displayName: 'Cafe A, 1 Street, Town',
  title: 'Cafe A',
  latitude: 50.0,
  longitude: 30.0,
);
const GeocodingResult _b = GeocodingResult(
  displayName: 'Cafe B, 2 Street, Town',
  title: 'Cafe B',
  latitude: 51.0,
  longitude: 31.0,
);

/// A geocoder whose reverse answers are released by the test, to check what
/// happens when answers arrive late or out of order.
class _ManualGeocoder implements GeocodingRepository {
  final List<Completer<GeocodingResult?>> pending = [];

  @override
  Future<List<GeocodingResult>> search(String query) async => const [];

  @override
  Future<GeocodingResult?> reverse(double latitude, double longitude) {
    final Completer<GeocodingResult?> c = Completer();
    pending.add(c);
    return c.future;
  }
}

void main() {
  late FakeGeocodingRepository geocoder;
  late FakeVenuesRepository venues;
  late FakeLocationService location;
  setUp(() {
    geocoder = FakeGeocodingRepository();
    venues = FakeVenuesRepository();
    location = FakeLocationService();
  });

  LocationPickerCubit make({
    GeocodingRepository? g,
    Duration debounce = const Duration(milliseconds: 20),
    String address = '',
  }) => LocationPickerCubit(
    geocoding: g ?? geocoder,
    venues: venues,
    location: location,
    initialCenter: _start,
    initialAddress: address,
    debounce: debounce,
  );

  group('search', () {
    blocTest<LocationPickerCubit, LocationPickerState>(
      'one match centres the map on it and fills the card',
      build: make,
      setUp: () => geocoder.results = const [_a],
      act: (LocationPickerCubit c) => c.search('cafe a'),
      verify: (LocationPickerCubit c) {
        expect(c.state.status, LocationPickerStatus.ready);
        expect(c.state.center, const LatLng(50.0, 30.0));
        expect(c.state.title, 'Cafe A');
        expect(c.state.recenterTick, 1); // tells the map to jump
        expect(geocoder.searches, ['cafe a']);
      },
    );

    blocTest<LocationPickerCubit, LocationPickerState>(
      'several matches are listed; picking one centres the map',
      build: make,
      setUp: () => geocoder.results = const [_a, _b],
      act: (LocationPickerCubit c) async {
        await c.search('cafe');
        expect(c.state.results, hasLength(2));
        expect(c.state.center, _start); // nothing chosen yet
        c.selectResult(_b);
      },
      verify: (LocationPickerCubit c) {
        expect(c.state.results, isEmpty);
        expect(c.state.center, const LatLng(51.0, 31.0));
        expect(c.state.address, _b.displayName);
      },
    );

    blocTest<LocationPickerCubit, LocationPickerState>(
      'nothing found: a message, the map stays',
      build: make,
      setUp: () => geocoder.results = const [],
      act: (LocationPickerCubit c) => c.search('zzzz'),
      verify: (LocationPickerCubit c) {
        expect(c.state.status, LocationPickerStatus.error);
        expect(c.state.message, contains('No places found'));
        expect(c.state.center, _start);
      },
    );

    blocTest<LocationPickerCubit, LocationPickerState>(
      'a network failure is reported, nothing else changes',
      build: make,
      setUp: () => geocoder.failure = const GeocodingFailure(
        GeocodingFailureType.network,
      ),
      act: (LocationPickerCubit c) => c.search('cafe'),
      verify: (LocationPickerCubit c) {
        expect(c.state.status, LocationPickerStatus.error);
        expect(c.state.message, isNotNull);
        expect(c.state.center, _start);
      },
    );

    blocTest<LocationPickerCubit, LocationPickerState>(
      'an empty query does nothing',
      build: make,
      act: (LocationPickerCubit c) => c.search('   '),
      expect: () => <LocationPickerState>[],
    );
  });

  group('map movement and reverse geocoding', () {
    test('dragging updates the coordinates without any request', () {
      final LocationPickerCubit c = make();
      c.mapMoving(const LatLng(1, 2));
      c.mapMoving(const LatLng(3, 4));
      expect(c.state.center, const LatLng(3, 4));
      expect(geocoder.reverses, isEmpty);
      c.close();
    });

    test('after the map stops, ONE lookup runs (debounce)', () async {
      final LocationPickerCubit c = make();
      c.mapMoved(const LatLng(1, 1));
      c.mapMoved(const LatLng(2, 2));
      c.mapMoved(const LatLng(3, 3));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(geocoder.reverses, [(3.0, 3.0)]);
      expect(c.state.status, LocationPickerStatus.ready);
      expect(c.state.address, contains('Test Street'));
      await c.close();
    });

    test('the card shows "resolving" while the lookup runs', () async {
      final _ManualGeocoder manual = _ManualGeocoder();
      final LocationPickerCubit c = make(g: manual);
      c.mapMoved(const LatLng(1, 1));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(c.state.status, LocationPickerStatus.resolving);
      manual.pending.single.complete(_a);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.status, LocationPickerStatus.ready);
      await c.close();
    });

    test('a late answer for an old position is discarded', () async {
      final _ManualGeocoder manual = _ManualGeocoder();
      final LocationPickerCubit c = make(g: manual);
      c.mapMoved(const LatLng(1, 1));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      // The user moves again before the first answer arrives.
      c.mapMoved(const LatLng(2, 2));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(manual.pending, hasLength(2));
      manual.pending[1].complete(_b);
      await Future<void>.delayed(Duration.zero);
      manual.pending[0].complete(_a); // stale
      await Future<void>.delayed(Duration.zero);
      expect(c.state.title, 'Cafe B');
      await c.close();
    });

    test(
      'a failed lookup keeps the old address; coordinates still move',
      () async {
        final LocationPickerCubit c = make(address: 'Old Street, Town');
        geocoder.failure = const GeocodingFailure(GeocodingFailureType.network);
        c.mapMoved(const LatLng(5, 6));
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(c.state.status, LocationPickerStatus.error);
        expect(c.state.address, 'Old Street, Town');
        expect(c.state.center, const LatLng(5, 6));
        // The user can still confirm, with the current point.
        expect(c.picked.latitude, 5);
        expect(c.picked.address, 'Old Street, Town');
        await c.close();
      },
    );

    test('with no address at all, confirming falls back to coordinates', () {
      final LocationPickerCubit c = make();
      expect(c.picked.address, '49.84000, 24.03000');
      expect(c.picked.longitude, 24.03);
      c.close();
    });
  });

  test('centerOnAddress finds an old record quietly', () async {
    geocoder.results = const [_a];
    final LocationPickerCubit c = make();
    await c.centerOnAddress('Cafe A');
    expect(c.state.center, const LatLng(50.0, 30.0));
    expect(c.state.recenterTick, 1);

    geocoder.failure = const GeocodingFailure(GeocodingFailureType.network);
    final LocationPickerCubit d = make();
    await d.centerOnAddress('Cafe A'); // no error, no crash
    expect(d.state.center, _start);
    await c.close();
    await d.close();
  });

  group('venues', () {
    const MapViewport city = MapViewport(
      bounds: GeoBounds(south: 49.83, west: 24.02, north: 49.85, east: 24.04),
      zoom: 16,
    );
    const MapViewport far = MapViewport(
      bounds: GeoBounds(south: 40, west: 20, north: 50, east: 30),
      zoom: 9,
    );

    test(
      'after the map stops, venues in view are loaded (zoomed in)',
      () async {
        final LocationPickerCubit c = make();
        c.mapMoved(const LatLng(49.84, 24.03), viewport: city);
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(venues.nearbyCalls, hasLength(1));
        expect(c.state.venues, hasLength(2));
        await c.close();
      },
    );

    test('zoomed far out, no venue request is made', () async {
      final LocationPickerCubit c = make();
      c.mapMoved(const LatLng(49.84, 24.03), viewport: far);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(venues.nearbyCalls, isEmpty);
      expect(c.state.venues, isEmpty);
      await c.close();
    });

    test('a failure to load venues is silent and keeps the address', () async {
      venues.failure = const GeocodingFailure(GeocodingFailureType.server);
      final LocationPickerCubit c = make();
      c.mapMoved(const LatLng(49.84, 24.03), viewport: city);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(c.state.status, LocationPickerStatus.ready); // address resolved
      expect(c.state.message, isNull);
      expect(c.state.venues, isEmpty);
      await c.close();
    });

    test('tapping a venue selects it; its name and kind go to the form', () {
      final LocationPickerCubit c = make();
      c.selectResult(FakeVenuesRepository.defaultVenues.first);
      expect(c.state.center.latitude, 49.8421);
      expect(c.state.selected?.title, 'Fake Roasters');
      expect(c.picked.name, 'Fake Roasters');
      expect(c.picked.category, PlaceCategory.cafe);
      c.close();
    });

    test('moving the map away forgets the chosen venue', () {
      final LocationPickerCubit c = make();
      c.selectResult(FakeVenuesRepository.defaultVenues.first);
      c.mapMoving(const LatLng(10, 10));
      expect(c.state.selected, isNull);
      expect(c.picked.name, isNull);
      expect(c.picked.category, isNull);
      c.close();
    });

    test('an address result carries no venue name or category', () {
      final LocationPickerCubit c = make();
      c.selectResult(_a);
      expect(c.picked.name, isNull);
      expect(c.picked.category, isNull);
      c.close();
    });
  });

  group('search merges venues and addresses', () {
    test('venues come first; the same spot is not listed twice', () async {
      venues.venues = const [
        GeocodingResult(
          displayName: 'Cafe A, Street',
          title: 'Cafe A',
          latitude: 50.0,
          longitude: 30.0,
          category: PlaceCategory.cafe,
        ),
      ];
      geocoder.results = const [_a, _b]; // _a is the same spot as the venue
      final LocationPickerCubit c = make();
      await c.search('cafe');
      expect(c.state.results.map((GeocodingResult r) => r.title), [
        'Cafe A',
        'Cafe B',
      ]);
      expect(venues.nameSearches, ['cafe']);
      expect(c.state.results.first.isVenue, isTrue);
      await c.close();
    });

    test('if venue search fails, the addresses still show', () async {
      venues.failure = const GeocodingFailure(GeocodingFailureType.timeout);
      geocoder.results = const [_a, _b];
      final LocationPickerCubit c = make();
      await c.search('cafe');
      expect(c.state.results, hasLength(2));
      await c.close();
    });

    test('if both fail, the user is told why', () async {
      venues.failure = const GeocodingFailure(GeocodingFailureType.network);
      geocoder.failure = const GeocodingFailure(GeocodingFailureType.network);
      final LocationPickerCubit c = make();
      await c.search('cafe');
      expect(c.state.status, LocationPickerStatus.error);
      expect(c.state.message, contains('No connection'));
      await c.close();
    });
  });

  group('my location', () {
    test('moves the map there, names the spot, loads venues', () async {
      final LocationPickerCubit c = make();
      await c.useMyLocation();
      expect(location.calls, 1);
      expect(c.state.center, const LatLng(49.8419, 24.0315));
      expect(c.state.recenterTick, 1);
      expect(c.state.status, LocationPickerStatus.ready);
      expect(c.state.address, contains('Test Street'));
      await Future<void>.delayed(Duration.zero);
      expect(c.state.venues, isNotEmpty);
      await c.close();
    });

    for (final LocationFailureType type in LocationFailureType.values) {
      test('$type is reported and the map stays', () async {
        location.failure = LocationFailure(type);
        final LocationPickerCubit c = make();
        await c.useMyLocation();
        expect(c.state.status, LocationPickerStatus.error);
        expect(c.state.message, LocationFailure(type).message);
        expect(c.state.center, _start);
        await c.close();
      });
    }
  });
}
