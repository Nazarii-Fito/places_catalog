import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/core/errors/places_failure.dart';
import 'package:places_catalog/data/mock/mock_places.dart';
import 'package:places_catalog/data/models/place.dart';
import 'package:places_catalog/data/models/place_photo.dart';
import 'package:places_catalog/data/repositories/fake_media_repository.dart';
import 'package:places_catalog/data/repositories/in_memory_places_repository.dart';
import 'package:places_catalog/data/repositories/media_repository.dart';
import 'package:places_catalog/data/repositories/places_repository.dart';
import 'package:places_catalog/features/places/bloc/create_place_bloc.dart';
import 'package:places_catalog/features/places/bloc/update_place_bloc.dart';

import '../helpers/recording_crash_reporter.dart';

/// A catalog whose writes always fail with [failure].
class _FailingSaves extends InMemoryPlacesRepository {
  _FailingSaves(this.failure);
  final PlacesFailure failure;

  @override
  Future<void> savePlace(String uid, Place place) => Future.error(failure);
}

PlacePhoto _local(String name) => PlacePhoto.local(
  '/tmp/$name.jpg',
  fileSizeBytes: 100,
  contentType: 'image/jpeg',
);

PlacePhoto _remote(String name) => PlacePhoto.remote(
  url: 'https://cdn.example/$name.jpg',
  storagePath: 'users/u1/p1/$name.jpg',
  fileSizeBytes: 100,
  contentType: 'image/jpeg',
  uploadedAt: DateTime.utc(2026, 11, 1),
);

Place _draft({List<PlacePhoto> photos = const []}) => Place.fromJson(
  {
    ...mockPlaces.first.toJson(),
    'id': '',
    'name': 'Brand New',
    'photos': <Object?>[],
  },
).copyWith(photos: photos, coverImage: photos.isNotEmpty ? photos.first : null);

void main() {
  late FakeMediaRepository media;
  late InMemoryPlacesRepository repo;
  late RecordingCrashReporter crash;

  setUp(() {
    media = FakeMediaRepository();
    repo = InMemoryPlacesRepository();
    crash = RecordingCrashReporter();
  });

  CreatePlaceBloc createBloc({
    PlacesRepository? repository,
    MediaRepository? m,
  }) => CreatePlaceBloc(
    uid: 'u1',
    repository: repository ?? repo,
    media: m ?? media,
    crashReporter: crash,
  );

  group('CreatePlaceBloc', () {
    blocTest<CreatePlaceBloc, CreatePlaceState>(
      'photos are uploaded one by one, then the place is saved',
      build: createBloc,
      act: (CreatePlaceBloc b) => b.add(
        CreatePlaceSubmitted(_draft(photos: [_local('a'), _local('b')])),
      ),
      expect: () => [
        const PlaceCreatingState(total: 2),
        const PlaceCreatingState(uploaded: 1, total: 2),
        const PlaceCreatingState(uploaded: 2, total: 2),
        isA<PlaceCreateSuccessState>(),
      ],
      verify: (CreatePlaceBloc b) async {
        expect(media.uploaded, hasLength(2));
        final Place saved = (b.state as PlaceCreateSuccessState).place;
        expect(saved.id, isNotEmpty);
        expect(saved.photos.every((PlacePhoto p) => p.isRemote), isTrue);
        expect(saved.coverImage, saved.photos.first); // uploaded copy
        expect(media.uploaded.first, startsWith('users/u1/${saved.id}/'));
        expect(
          (await repo.loadPlaces('u1')).any((Place p) => p.id == saved.id),
          isTrue,
        );
      },
    );

    blocTest<CreatePlaceBloc, CreatePlaceState>(
      'a place without photos needs no storage',
      build: createBloc,
      act: (CreatePlaceBloc b) => b.add(CreatePlaceSubmitted(_draft())),
      expect: () => [
        const PlaceCreatingState(),
        isA<PlaceCreateSuccessState>(),
      ],
      verify: (_) => expect(media.uploaded, isEmpty),
    );

    blocTest<CreatePlaceBloc, CreatePlaceState>(
      'bundled and already uploaded photos are never uploaded again',
      build: createBloc,
      act: (CreatePlaceBloc b) => b.add(
        CreatePlaceSubmitted(
          _draft(
            photos: [
              const PlacePhoto.asset('assets/images/photo_coffee.jpg'),
              _remote('old'),
              _local('new'),
            ],
          ),
        ),
      ),
      verify: (CreatePlaceBloc b) {
        expect(media.uploaded, hasLength(1));
        expect((b.state as PlaceCreateSuccessState).place.photos, hasLength(3));
      },
    );

    blocTest<CreatePlaceBloc, CreatePlaceState>(
      'a failed upload rolls back the files already uploaded; nothing is saved',
      build: createBloc,
      setUp: () => media.failOnUpload = 2,
      act: (CreatePlaceBloc b) => b.add(
        CreatePlaceSubmitted(
          _draft(photos: [_local('a'), _local('b'), _local('c')]),
        ),
      ),
      verify: (CreatePlaceBloc b) async {
        expect(media.uploaded, hasLength(1));
        expect(media.deleted, media.uploaded); // the first file was removed
        final CreatePlaceState s = b.state;
        expect(s, isA<PlaceCreateErrorState>());
        expect((s as PlaceCreateErrorState).retryable, isTrue); // offline
        expect(await repo.loadPlaces('u1'), hasLength(mockPlaces.length));
      },
    );

    blocTest<CreatePlaceBloc, CreatePlaceState>(
      'a failed database write rolls back all uploads and is not retryable '
      'when access is denied',
      build: () => createBloc(
        repository: _FailingSaves(
          const PlacesFailure(PlacesFailureType.permissionDenied),
        ),
      ),
      act: (CreatePlaceBloc b) => b.add(
        CreatePlaceSubmitted(_draft(photos: [_local('a'), _local('b')])),
      ),
      verify: (CreatePlaceBloc b) {
        expect(media.deleted, unorderedEquals(media.uploaded));
        expect(media.uploaded, hasLength(2));
        final PlaceCreateErrorState s = b.state as PlaceCreateErrorState;
        expect(s.retryable, isFalse);
      },
    );

    blocTest<CreatePlaceBloc, CreatePlaceState>(
      'without storage keys, photos give a clear, non-retryable error',
      build: () => createBloc(m: const NotConfiguredMediaRepository()),
      act: (CreatePlaceBloc b) =>
          b.add(CreatePlaceSubmitted(_draft(photos: [_local('a')]))),
      verify: (CreatePlaceBloc b) {
        final PlaceCreateErrorState s = b.state as PlaceCreateErrorState;
        expect(s.message, contains('not configured'));
        expect(s.retryable, isFalse);
      },
    );

    blocTest<CreatePlaceBloc, CreatePlaceState>(
      'a second submit while saving is ignored',
      build: createBloc,
      setUp: () => media.gate = Completer<void>(),
      act: (CreatePlaceBloc b) async {
        b.add(CreatePlaceSubmitted(_draft(photos: [_local('a')])));
        b.add(CreatePlaceSubmitted(_draft(photos: [_local('b')])));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        media.gate!.complete();
      },
      wait: const Duration(milliseconds: 30),
      verify: (_) => expect(media.uploaded, hasLength(1)),
    );

    blocTest<CreatePlaceBloc, CreatePlaceState>(
      'reset returns to idle after an error',
      build: createBloc,
      seed: () => const PlaceCreateErrorState(message: 'x', retryable: true),
      act: (CreatePlaceBloc b) => b.add(const CreatePlaceReset()),
      expect: () => [const CreatePlaceIdle()],
    );
  });

  group('UpdatePlaceBloc', () {
    late Place original;
    setUp(() {
      original = mockPlaces.first.copyWith(
        id: 'p1',
        photos: [_remote('a'), _remote('b')],
        coverImage: _remote('a'),
      );
    });

    UpdatePlaceBloc updateBloc({PlacesRepository? repository}) =>
        UpdatePlaceBloc(
          uid: 'u1',
          repository: repository ?? repo,
          media: media,
          crashReporter: crash,
        );

    blocTest<UpdatePlaceBloc, UpdatePlaceState>(
      'kept photos stay, a new one is uploaded, a removed one is deleted',
      build: updateBloc,
      act: (UpdatePlaceBloc b) => b.add(
        UpdatePlaceSubmitted(
          original: original,
          draft: original.copyWith(photos: [_remote('a'), _local('c')]),
        ),
      ),
      verify: (UpdatePlaceBloc b) {
        expect(media.uploaded, hasLength(1)); // only the new file
        expect(media.deleted, ['users/u1/p1/b.jpg']); // only the removed one
        final Place saved = (b.state as PlaceUpdateSuccessState).place;
        expect(saved.photos, hasLength(2));
        expect(saved.photos.first.storagePath, 'users/u1/p1/a.jpg');
        expect(saved.id, 'p1');
      },
    );

    blocTest<UpdatePlaceBloc, UpdatePlaceState>(
      'notes only: no uploads and no deletes',
      build: updateBloc,
      act: (UpdatePlaceBloc b) => b.add(
        UpdatePlaceSubmitted(
          original: original,
          draft: original.copyWith(
            review: original.review!.copyWith(textNote: 'new note'),
          ),
          origin: UpdateOrigin.inline,
        ),
      ),
      verify: (UpdatePlaceBloc b) {
        expect(media.uploaded, isEmpty);
        expect(media.deleted, isEmpty);
        final PlaceUpdateSuccessState s = b.state as PlaceUpdateSuccessState;
        expect(s.origin, UpdateOrigin.inline);
        expect(s.place.review!.textNote, 'new note');
      },
    );

    blocTest<UpdatePlaceBloc, UpdatePlaceState>(
      'a failed upload keeps the old record AND the files meant for deletion',
      build: updateBloc,
      setUp: () => media.failOnUpload = 2,
      act: (UpdatePlaceBloc b) => b.add(
        UpdatePlaceSubmitted(
          original: original,
          draft: original.copyWith(photos: [_local('c'), _local('d')]),
        ),
      ),
      verify: (UpdatePlaceBloc b) {
        expect(b.state, isA<PlaceUpdateErrorState>());
        // Only the rollback of the first new upload; the old files stay.
        expect(media.deleted, media.uploaded);
        expect(media.deleted, hasLength(1));
      },
    );

    blocTest<UpdatePlaceBloc, UpdatePlaceState>(
      'a failed database write does not delete the removed photos',
      build: () => updateBloc(
        repository: _FailingSaves(
          const PlacesFailure(PlacesFailureType.offline),
        ),
      ),
      act: (UpdatePlaceBloc b) => b.add(
        UpdatePlaceSubmitted(
          original: original,
          draft: original.copyWith(photos: [_remote('a'), _local('c')]),
        ),
      ),
      verify: (UpdatePlaceBloc b) {
        expect(b.state, isA<PlaceUpdateErrorState>());
        expect(media.deleted, media.uploaded); // only the rollback
        expect(media.deleted.contains('users/u1/p1/b.jpg'), isFalse);
      },
    );

    blocTest<UpdatePlaceBloc, UpdatePlaceState>(
      'a failed cleanup of removed photos never fails the save',
      build: updateBloc,
      setUp: () => media.failDeletes = true,
      act: (UpdatePlaceBloc b) => b.add(
        UpdatePlaceSubmitted(
          original: original,
          draft: original.copyWith(photos: [_remote('a')]),
        ),
      ),
      verify: (UpdatePlaceBloc b) {
        expect(b.state, isA<PlaceUpdateSuccessState>());
        expect(crash.errors, isNotEmpty); // logged as an orphan
      },
    );

    blocTest<UpdatePlaceBloc, UpdatePlaceState>(
      'a second submit while saving is ignored',
      build: updateBloc,
      setUp: () => media.gate = Completer<void>(),
      act: (UpdatePlaceBloc b) async {
        final UpdatePlaceSubmitted e = UpdatePlaceSubmitted(
          original: original,
          draft: original.copyWith(photos: [_remote('a'), _local('c')]),
        );
        b.add(e);
        b.add(e);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        media.gate!.complete();
      },
      wait: const Duration(milliseconds: 30),
      verify: (_) => expect(media.uploaded, hasLength(1)),
    );
  });
}
