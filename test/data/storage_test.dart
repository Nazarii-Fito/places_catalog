import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/data/mock/mock_places.dart';
import 'package:places_catalog/data/models/place.dart';
import 'package:places_catalog/data/repositories/in_memory_places_repository.dart';
import 'package:places_catalog/data/repositories/local_places_repository.dart';
import 'package:places_catalog/data/repositories/shared_prefs_settings_repository.dart';
import 'package:places_catalog/data/services/crash_reporter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records non-fatal reports so tests can assert on them.
class _RecordingCrashReporter extends NoopCrashReporter {
  _RecordingCrashReporter();
  final List<Object> errors = [];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async => errors.add(error);
}

void main() {
  group('Place JSON', () {
    test('every mock place survives a toJson/fromJson round trip', () {
      for (final Place place in mockPlaces) {
        final String text = jsonEncode(place.toJson());
        final Place back = Place.fromJson(
          jsonDecode(text) as Map<String, Object?>,
        );
        expect(jsonEncode(back.toJson()), text);
        expect(back.category, place.category);
        expect(back.visitDate, place.visitDate);
        expect(back.review?.updatedAt, place.review?.updatedAt);
        expect(back.photos.length, place.photos.length);
      }
    });

    test('a place without a review and coordinates round-trips', () {
      final Place bare = mockPlaces.first.copyWith().toJson()['review'] == null
          ? mockPlaces.first
          : Place.fromJson({
              ...mockPlaces.first.toJson(),
              'review': null,
              'latitude': null,
              'longitude': null,
            });
      expect(bare.review, isNull);
      expect(bare.latitude, isNull);
      expect(Place.fromJson(bare.toJson()).review, isNull);
    });

    test('an unknown category name is rejected', () {
      final Map<String, Object?> json = {
        ...mockPlaces.first.toJson(),
        'category': 'spaceship',
      };
      expect(() => Place.fromJson(json), throwsArgumentError);
    });
  });

  group('LocalPlacesRepository', () {
    late Directory dir;
    late _RecordingCrashReporter crash;

    LocalPlacesRepository make() =>
        LocalPlacesRepository(directory: () async => dir, crashReporter: crash);

    setUp(() {
      dir = Directory.systemTemp.createTempSync('places_test');
      crash = _RecordingCrashReporter();
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('first run seeds the demo catalog and writes the file', () async {
      final List<Place> places = await make().loadPlaces('u1');
      expect(places.length, mockPlaces.length);
      expect(File('${dir.path}/places_u1.json').existsSync(), isTrue);
    });

    test('changes persist across a new repository instance', () async {
      final LocalPlacesRepository a = make();
      final Place added = mockPlaces.first.copyWith(name: 'Brand New');
      await a.savePlace(
        'u1',
        Place.fromJson({...added.toJson(), 'id': 'new-1'}),
      );
      await a.deletePlace('u1', mockPlaces[1].id);
      await a.savePlace('u1', mockPlaces.first.copyWith(isFavorite: false));

      final List<Place> reloaded = await make().loadPlaces('u1');
      expect(reloaded.map((Place p) => p.id), contains('new-1'));
      expect(
        reloaded.map((Place p) => p.id),
        isNot(contains(mockPlaces[1].id)),
      );
      expect(
        reloaded
            .firstWhere((Place p) => p.id == mockPlaces.first.id)
            .isFavorite,
        isFalse,
      );
      expect(reloaded.length, mockPlaces.length);
    });

    test('users are isolated from each other', () async {
      final LocalPlacesRepository repo = make();
      await repo.deletePlace('alice', mockPlaces.first.id);
      expect((await repo.loadPlaces('alice')).length, mockPlaces.length - 1);
      expect((await make().loadPlaces('bob')).length, mockPlaces.length);
    });

    test('a damaged file is reported and replaced by the seed', () async {
      File('${dir.path}/places_u1.json').writeAsStringSync('{ not json');
      final List<Place> places = await make().loadPlaces('u1');
      expect(places.length, mockPlaces.length);
      expect(crash.errors, hasLength(1));
      // The file was repaired: the next start reads it without errors.
      await make().loadPlaces('u1');
      expect(crash.errors, hasLength(1));
    });

    test('no temporary file is left behind after writing', () async {
      final LocalPlacesRepository repo = make();
      await repo.savePlace('u1', mockPlaces.first);
      expect(
        dir.listSync().where((FileSystemEntity e) => e.path.endsWith('.tmp')),
        isEmpty,
      );
    });
  });

  group('InMemoryPlacesRepository', () {
    test('save, update and delete work per user', () async {
      final InMemoryPlacesRepository repo = InMemoryPlacesRepository();
      await repo.deletePlace('a', mockPlaces.first.id);
      expect((await repo.loadPlaces('a')).length, mockPlaces.length - 1);
      expect((await repo.loadPlaces('b')).length, mockPlaces.length);
    });

    test('failLoad makes loading throw', () {
      final InMemoryPlacesRepository repo = InMemoryPlacesRepository(
        failLoad: true,
      );
      expect(repo.loadPlaces('a'), throwsStateError);
    });
  });

  group('SharedPrefsSettingsRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults are empty, saved values come back per user', () async {
      final SharedPrefsSettingsRepository repo = SharedPrefsSettingsRepository(
        await SharedPreferences.getInstance(),
      );
      expect((await repo.loadCatalogView('u1')).filter, isNull);

      await repo.saveCatalogView('u1', filter: 'cafes', sort: 'name');
      await repo.saveCatalogView('u2', sort: 'rating');

      final p1 = await repo.loadCatalogView('u1');
      expect((p1.filter, p1.sort), ('cafes', 'name'));
      final p2 = await repo.loadCatalogView('u2');
      expect((p2.filter, p2.sort), (null, 'rating'));
    });
  });
}
