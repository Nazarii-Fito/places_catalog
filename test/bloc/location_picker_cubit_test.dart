import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:places_catalog/core/errors/geocoding_failure.dart';
import 'package:places_catalog/data/models/geocoding_result.dart';
import 'package:places_catalog/data/repositories/geocoding_repository.dart';
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
  setUp(() => geocoder = FakeGeocodingRepository());

  LocationPickerCubit make({
    GeocodingRepository? g,
    Duration debounce = const Duration(milliseconds: 20),
    String address = '',
  }) => LocationPickerCubit(
    geocoding: g ?? geocoder,
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
}
