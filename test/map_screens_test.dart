import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/core/errors/geocoding_failure.dart';
import 'package:places_catalog/core/widgets/osm_tile_layer.dart';
import 'package:places_catalog/data/mock/mock_places.dart';
import 'package:places_catalog/data/models/geocoding_result.dart';
import 'package:places_catalog/data/models/place.dart';
import 'package:places_catalog/data/repositories/geocoding_repository.dart';
import 'package:places_catalog/data/repositories/in_memory_places_repository.dart';
import 'package:places_catalog/data/services/map_launcher.dart';
import 'package:places_catalog/features/places/screens/location_picker_screen.dart';
import 'package:places_catalog/features/places/screens/place_details_screen.dart';
import 'package:places_catalog/features/places/place_details_args.dart';
import 'package:places_catalog/features/shell/main_shell.dart';

import 'helpers/test_harness.dart';

/// Opens the picker from a button and records what it returns.
Widget _host(Object? Function(Object?) onResult, {LocationPickerArgs? args}) {
  return Builder(
    builder: (BuildContext context) => TextButton(
      onPressed: () async {
        final Object? r = await Navigator.of(context).push<Object?>(
          MaterialPageRoute<Object?>(
            builder: (_) => LocationPickerScreen(initial: args),
          ),
        );
        onResult(r);
      },
      child: const Text('open'),
    ),
  );
}

void main() {
  setUpAll(loadInterFont);

  group('Location Picker', () {
    testWidgets('shows a real map, the pin, the credit and the card', (
      tester,
    ) async {
      useIPhone17(tester);
      await tester.pumpWidget(testApp(_host((_) => null)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      expect(find.text('Confirm Location'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // No address yet: the hint and the default centre's coordinates.
      expect(find.text('Move the map to choose a place'), findsOneWidget);
      expect(find.textContaining('° N'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('submitting a search fills the card with the result', (
      tester,
    ) async {
      useIPhone17(tester);
      final FakeGeocodingRepository geocoder = FakeGeocodingRepository();
      await tester.pumpWidget(testApp(_host((_) => null), geocoding: geocoder));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'fake cafe');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(geocoder.searches, ['fake cafe']);
      expect(find.text('Fake Cafe'), findsOneWidget); // card title
      expect(find.textContaining('1 Test Street'), findsWidgets);
      expect(find.text('50.4501° N, 30.5234° E'), findsOneWidget);
    });

    testWidgets('several matches are listed under the search panel', (
      tester,
    ) async {
      useIPhone17(tester);
      final FakeGeocodingRepository geocoder = FakeGeocodingRepository(
        results: const [
          GeocodingResult(
            displayName: 'Alpha, Street 1',
            title: 'Alpha',
            latitude: 1,
            longitude: 2,
          ),
          GeocodingResult(
            displayName: 'Beta, Street 2',
            title: 'Beta',
            latitude: 3,
            longitude: 4,
          ),
        ],
      );
      await tester.pumpWidget(testApp(_host((_) => null), geocoding: geocoder));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'x');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      expect(find.text('Beta'), findsOneWidget); // now the card title
      expect(find.text('3.0000° N, 4.0000° E'), findsOneWidget);
    });

    testWidgets('a failed search shows a message and keeps working', (
      tester,
    ) async {
      useIPhone17(tester);
      final FakeGeocodingRepository geocoder = FakeGeocodingRepository(
        failure: const GeocodingFailure(GeocodingFailureType.network),
      );
      await tester.pumpWidget(testApp(_host((_) => null), geocoding: geocoder));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'x');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.textContaining('No connection'), findsOneWidget);
      expect(find.text('Confirm Location'), findsOneWidget);
    });

    testWidgets('Confirm returns the typed result; Cancel returns null', (
      tester,
    ) async {
      useIPhone17(tester);
      final List<Object?> results = [];
      await tester.pumpWidget(
        testApp(
          _host((Object? r) {
            results.add(r);
            return null;
          }),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'fake cafe');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Location'));
      await tester.pumpAndSettle();

      final PickedLocation picked = results.single! as PickedLocation;
      expect(picked.address, contains('Fake Cafe'));
      expect(picked.latitude, 50.4501);
      expect(picked.longitude, 30.5234);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(results.last, isNull);
    });

    testWidgets('opens at the place\'s own point when editing', (tester) async {
      useIPhone17(tester);
      await tester.pumpWidget(
        testApp(
          _host(
            (_) => null,
            args: const LocationPickerArgs(
              address: 'Home, Street 5',
              latitude: 40.7587,
              longitude: -73.9787,
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('40.7587° N, 73.9787° W'), findsOneWidget);
      expect(find.text('Home, Street 5'), findsWidgets);
    });

    testWidgets('network tiles are off in tests (no HTTP)', (tester) async {
      expect(OsmTileLayer.useNetworkTiles, isFalse);
      expect(OsmTileLayer.packageName, 'ua.lpnu.pz33.placesCatalog');
      expect(
        OsmTileLayer.urlTemplate,
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );
    });
  });

  group('Place Details map', () {
    Future<FakeMapLauncher> openDetails(
      WidgetTester tester,
      Place place, {
      FakeMapLauncher? launcher,
    }) async {
      useIPhone(tester, size: const Size(390, 2400));
      final FakeMapLauncher l = launcher ?? FakeMapLauncher();
      await tester.pumpWidget(
        testApp(
          PlaceDetailsScreen(args: PlaceDetailsArgs(placeId: place.id)),
          places: InMemoryPlacesRepository(seed: [place]),
          mapLauncher: l,
        ),
      );
      await tester.pumpAndSettle();
      return l;
    }

    testWidgets('a place with coordinates shows a still map; tap opens Maps', (
      tester,
    ) async {
      final Place place = mockPlaces.first; // has coordinates
      final FakeMapLauncher launcher = await openDetails(tester, place);

      final FlutterMap map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.options.interactionOptions.flags, InteractiveFlag.none);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);

      await tester.ensureVisible(find.byType(FlutterMap));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FlutterMap));
      await tester.pumpAndSettle();
      expect(launcher.opened.single, (
        place.latitude,
        place.longitude,
        place.name,
      ));

      await tester.tap(find.text('Open in Apple Maps'));
      await tester.pumpAndSettle();
      expect(launcher.opened, hasLength(2));
    });

    testWidgets('a place without coordinates shows "Location is not set"', (
      tester,
    ) async {
      final Place old = Place.fromJson({
        ...mockPlaces.first.toJson(),
        'latitude': null,
        'longitude': null,
      });
      final FakeMapLauncher launcher = await openDetails(tester, old);
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('Location is not set'), findsOneWidget);
      expect(find.text('Open in Apple Maps'), findsNothing);
      expect(launcher.opened, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('if no Maps app opens, the user is told', (tester) async {
      await openDetails(
        tester,
        mockPlaces.first,
        launcher: FakeMapLauncher(succeeds: false),
      );
      await tester.ensureVisible(find.text('Open in Apple Maps'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open in Apple Maps'));
      await tester.pumpAndSettle();
      expect(find.text('Could not open the Maps app.'), findsOneWidget);
    });
  });

  testWidgets('the form saves the point picked on the map', (tester) async {
    useIPhone(tester, size: const Size(390, 2400));
    final InMemoryPlacesRepository repo = InMemoryPlacesRepository(seed: []);
    await tester.pumpWidget(testApp(const MainShell(), places: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(RegExp('Add new place')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'Mapped Cafe');
    await tester.tap(find.text('Choose location'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'fake cafe');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm Location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Place Record'));
    await tester.pumpAndSettle();

    final List<Place> stored = (await tester.runAsync(
      () => repo.loadPlaces('demo-uid'),
    ))!;
    final Place saved = stored.single;
    expect(saved.name, 'Mapped Cafe');
    expect(saved.latitude, 50.4501);
    expect(saved.longitude, 30.5234);
    expect(saved.address, contains('Fake Cafe'));
  });
}
