import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/core/errors/places_failure.dart';
import 'package:places_catalog/data/firestore/in_memory_places_document_store.dart';
import 'package:places_catalog/data/firestore/place_mapper.dart';
import 'package:places_catalog/data/mock/mock_places.dart';
import 'package:places_catalog/data/models/place.dart';
import 'package:places_catalog/data/models/place_photo.dart';
import 'package:places_catalog/data/repositories/firestore_places_repository.dart';
import 'package:places_catalog/data/repositories/places_repository.dart';

import '../helpers/recording_crash_reporter.dart';

final PlacePhoto _remote = PlacePhoto.remote(
  url: 'https://x.supabase.co/storage/v1/object/public/place-photos/a.jpg',
  storagePath: 'users/u1/p1/a.jpg',
  fileSizeBytes: 1234,
  contentType: 'image/jpeg',
  uploadedAt: DateTime.utc(2026, 11, 1, 12),
);

Place _place(String id, {DateTime? visit, DateTime? created}) =>
    Place.fromJson({
      ...mockPlaces.first.toJson(),
      'id': id,
      'name': 'Place $id',
      'visitDate': (visit ?? DateTime(2026, 1, 1)).toIso8601String(),
      'createdAt': created?.toIso8601String(),
    });

void main() {
  group('PlaceMapper', () {
    test('every demo place survives a map round trip', () {
      for (final Place place in mockPlaces) {
        final Place back = PlaceMapper.fromMap(
          place.id,
          PlaceMapper.toMap(place),
        );
        expect(back.toJson(), place.toJson());
      }
    });

    test('remote photo metadata and null coordinates round-trip', () {
      final Place place = _place('p1')
          .copyWith(photos: [_remote], coverImage: _remote);
      final Map<String, Object?> map = PlaceMapper.toMap(
        Place.fromJson({
          ...place.toJson(),
          'latitude': null,
          'longitude': null,
          'review': null,
        }),
      );
      expect(map['latitude'], isNull);
      expect(map['review'], isNull);
      final Place back = PlaceMapper.fromMap('p1', map);
      expect(back.latitude, isNull);
      expect(back.review, isNull);
      expect(back.photos.single.storagePath, 'users/u1/p1/a.jpg');
      expect(back.photos.single.uploadedAt, DateTime.utc(2026, 11, 1, 12));
      expect(back.coverImage, _remote);
    });

    test('a local (not uploaded) photo is refused', () {
      final Place place = _place('p1').copyWith(
        photos: [const PlacePhoto.local('/tmp/a.jpg', fileSizeBytes: 5)],
      );
      expect(() => PlaceMapper.toMap(place), throwsStateError);
    });

    test('photos of all three kinds are told apart', () {
      expect(const PlacePhoto.asset('a.jpg').kind, PhotoKind.asset);
      expect(const PlacePhoto.local('/a', fileSizeBytes: 1).isLocal, isTrue);
      expect(_remote.isRemote, isTrue);
      expect(PlacePhoto.fromJson(_remote.toJson()), _remote);
    });

    test('Lab 5 photo JSON still loads', () {
      final PlacePhoto photo = PlacePhoto.fromJson({
        'imageAsset': 'assets/images/a.jpg',
        'fileSizeBytes': 10,
      });
      expect(photo.kind, PhotoKind.asset);
      expect(photo.fileSizeBytes, 10);
    });
  });

  group('FirestorePlacesRepository', () {
    late InMemoryPlacesDocumentStore store;
    late RecordingCrashReporter crash;

    FirestorePlacesRepository make({
      Duration timeout = const Duration(milliseconds: 50),
    }) => FirestorePlacesRepository(
      store: store,
      crashReporter: crash,
      writeTimeout: timeout,
    );

    setUp(() {
      store = InMemoryPlacesDocumentStore();
      crash = RecordingCrashReporter();
    });

    test('a new user gets the demo catalog, exactly once', () async {
      final FirestorePlacesRepository repo = make();
      expect((await repo.loadPlaces('u1')).length, mockPlaces.length);
      // Delete everything, then "restart": the demo data must not return.
      for (final Place p in mockPlaces) {
        await repo.deletePlace('u1', p.id);
      }
      final FirestorePlacesRepository restarted = make();
      expect(await restarted.loadPlaces('u1'), isEmpty);
      expect(store.seedCount, 1);
    });

    test('users are isolated', () async {
      final FirestorePlacesRepository repo = make();
      await repo.loadPlaces('alice'); // seeded
      await repo.deletePlace('alice', mockPlaces.first.id);
      expect((await repo.loadPlaces('alice')).length, mockPlaces.length - 1);
      expect((await repo.loadPlaces('bob')).length, mockPlaces.length);
    });

    test('save inserts and replaces; the listener sees both', () async {
      final FirestorePlacesRepository repo = make();
      final List<int> counts = [];
      final StreamSubscription<List<Place>> sub = repo
          .watchPlaces('u1')
          .listen((List<Place> p) => counts.add(p.length));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final String id = repo.newPlaceId('u1');
      await repo.savePlace('u1', _place(id));
      await repo.savePlace('u1', _place(id).copyWith(name: 'Renamed'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      expect(counts.last, mockPlaces.length + 1);
      final Place saved = (await repo.loadPlaces('u1'))
          .firstWhere((Place p) => p.id == id);
      expect(saved.name, 'Renamed');
      expect(saved.createdAt, isNotNull); // stamped by the store
    });

    test('order: visit date, then creation time, then id', () async {
      final FirestorePlacesRepository repo = make();
      await repo.loadPlaces('u1'); // seed
      for (final Place p in mockPlaces) {
        await repo.deletePlace('u1', p.id);
      }
      final DateTime day = DateTime(2030, 5, 5);
      await repo.savePlace(
        'u1',
        _place('a', visit: day, created: DateTime(2026, 1, 1)),
      );
      await repo.savePlace(
        'u1',
        _place('b', visit: day, created: DateTime(2026, 2, 1)),
      );
      await repo.savePlace('u1', _place('c', visit: DateTime(2031, 1, 1)));
      final List<Place> list = await repo.loadPlaces('u1');
      expect(list.map((Place p) => p.id), ['c', 'b', 'a']);
    });

    test('pagination walks the whole catalog', () async {
      final FirestorePlacesRepository repo = make();
      final List<String> ids = [];
      Object? cursor;
      int pages = 0;
      do {
        final PlacesPage page = await repo.loadPage(
          'u1',
          perPage: 2,
          cursor: cursor,
        );
        ids.addAll(page.places.map((Place p) => p.id));
        cursor = page.cursor;
        pages++;
      } while (cursor != null);
      expect(ids.length, mockPlaces.length);
      expect(ids.toSet().length, mockPlaces.length);
      expect(pages, greaterThan(1));
    });

    test('permission-denied becomes a typed failure', () async {
      final FirestorePlacesRepository repo = make();
      await repo.loadPlaces('u1');
      store.failWith = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      await expectLater(
        repo.savePlace('u1', _place('x')),
        throwsA(
          isA<PlacesFailure>().having(
            (PlacesFailure f) => f.type,
            'type',
            PlacesFailureType.permissionDenied,
          ),
        ),
      );
    });

    test('unavailable becomes offline and is retryable', () async {
      final FirestorePlacesRepository repo = make();
      await repo.loadPlaces('u1');
      store.failWith = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      try {
        await repo.deletePlace('u1', 'x');
        fail('should throw');
      } on PlacesFailure catch (f) {
        expect(f.type, PlacesFailureType.offline);
        expect(f.isRetryable, isTrue);
      }
    });

    test('an unknown error is reported to Crashlytics', () async {
      final FirestorePlacesRepository repo = make();
      await repo.loadPlaces('u1');
      store.failWith = StateError('boom');
      await expectLater(
        repo.savePlace('u1', _place('x')),
        throwsA(isA<PlacesFailure>()),
      );
      expect(crash.errors, hasLength(1));
    });

    test(
      'a write with no confirmation counts as queued offline (no throw)',
      () async {
        final FirestorePlacesRepository repo = make();
        await repo.loadPlaces('u1');
        store.hang = true;
        // Completes after the timeout instead of hanging forever.
        await repo.savePlace('u1', _place('x'));
      },
    );

    test('a damaged document is skipped and reported', () async {
      final FirestorePlacesRepository repo = make();
      await repo.loadPlaces('u1');
      await store.set('u1', 'bad', {'name': 'X', 'category': 'spaceship'});
      final List<Place> list = await repo.loadPlaces('u1');
      expect(list.length, mockPlaces.length);
      expect(crash.errors, isNotEmpty);
    });
  });
}
