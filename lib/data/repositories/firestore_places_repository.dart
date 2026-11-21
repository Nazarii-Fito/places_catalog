// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import '../../core/errors/places_failure.dart';
import '../firestore/place_mapper.dart';
import '../firestore/places_document_store.dart';
import '../mock/mock_places.dart';
import '../models/place.dart';
import '../services/crash_reporter.dart';
import 'places_ordering.dart';
import 'places_repository.dart';

/// The catalog in Cloud Firestore: `users/{uid}/places/{placeId}`.
///
/// * **Live:** [watchPlaces] follows the collection, so a change made on
///   another device (or by the user's own write) appears without a reload.
/// * **Seeded once:** a new user gets the demo catalog the first time only;
///   `users/{uid}.seededAt` stops it from coming back after "delete all".
/// * **Offline:** Firestore keeps a local cache, so reads and listeners keep
///   working without a network. A write only *completes* once the server
///   confirms it, so [savePlace] gives up waiting after [writeTimeout] and
///   treats that as "saved locally, will sync" — the SDK retries by itself.
///   (A failure that arrives later, e.g. rules refused it, is reported to
///   Crashlytics.)
/// * **Errors:** SDK exceptions become [PlacesFailure]; a damaged document
///   is skipped and reported instead of breaking the whole list.
class FirestorePlacesRepository implements PlacesRepository {
  FirestorePlacesRepository({
    required PlacesDocumentStore store,
    required CrashReporter crashReporter,
    List<Place>? seed,
    this.writeTimeout = const Duration(seconds: 4),
  }) : _store = store,
       _crashReporter = crashReporter,
       _seed = seed ?? mockPlaces;

  final PlacesDocumentStore _store;
  final CrashReporter _crashReporter;
  final List<Place> _seed;

  /// How long a save is awaited before it counts as "queued offline".
  final Duration writeTimeout;

  final Set<String> _seededThisRun = {};

  /// Seeds at most once per user per app run (the server flag makes it
  /// once ever). A *network* failure must not block reading the cache.
  Future<void> _ensureSeeded(String uid) async {
    if (_seededThisRun.contains(uid)) return;
    try {
      await _store.seedOnce(uid, [
        for (final Place p in _seed) PlaceDoc(p.id, PlaceMapper.toMap(p)),
      ]);
      _seededThisRun.add(uid);
    } catch (error, stack) {
      final PlacesFailure failure = _toFailure(error, stack);
      if (failure.type != PlacesFailureType.offline) throw failure;
      // Offline: show what is cached; seeding is retried on the next load.
    }
  }

  @override
  Stream<List<Place>> watchPlaces(String uid) {
    late final StreamController<List<Place>> controller;
    StreamSubscription<List<PlaceDoc>>? subscription;

    Future<void> start() async {
      try {
        await _ensureSeeded(uid);
      } catch (error, stack) {
        controller.addError(_toFailure(error, stack));
        await controller.close();
        return;
      }
      if (controller.isClosed) return;
      subscription = _store
          .watch(uid)
          .listen(
            (List<PlaceDoc> docs) => controller.add(sortPlaces(_decode(docs))),
            onError: (Object error, StackTrace stack) =>
                controller.addError(_toFailure(error, stack)),
            onDone: controller.close,
          );
    }

    // A StreamController (not `async*`) so cancelling never hangs.
    controller = StreamController<List<Place>>(
      onListen: start,
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<List<Place>> loadPlaces(String uid) => watchPlaces(uid).first;

  @override
  Future<PlacesPage> loadPage(
    String uid, {
    int perPage = 20,
    Object? cursor,
  }) async {
    await _ensureSeeded(uid);
    try {
      final List<PlaceDoc> docs = await _store.fetchPage(
        uid,
        limit: perPage,
        after: cursor,
      );
      return PlacesPage(
        places: sortPlaces(_decode(docs)),
        // A full page may have a successor; a short one is the last.
        cursor: docs.length == perPage ? docs.last.cursor : null,
      );
    } catch (error, stack) {
      throw _toFailure(error, stack);
    }
  }

  @override
  String newPlaceId(String uid) => _store.newId(uid);

  @override
  Future<void> savePlace(String uid, Place place) =>
      _write(_store.set(uid, place.id, PlaceMapper.toMap(place)), 'Save place');

  @override
  Future<void> deletePlace(String uid, String placeId) =>
      _write(_store.delete(uid, placeId), 'Delete place');

  Future<void> _write(Future<void> write, String what) async {
    try {
      await write.timeout(writeTimeout);
    } on TimeoutException {
      // No confirmation yet (typically offline): the write is queued in the
      // local cache and the SDK will deliver it. Watch for a late failure.
      unawaited(
        write.catchError((Object error, StackTrace stack) {
          _crashReporter.recordError(
            error,
            stack,
            reason: '$what failed after it was queued offline',
          );
        }),
      );
    } catch (error, stack) {
      throw _toFailure(error, stack);
    }
  }

  List<Place> _decode(List<PlaceDoc> docs) {
    final List<Place> places = [];
    for (final PlaceDoc doc in docs) {
      try {
        places.add(PlaceMapper.fromMap(doc.id, doc.data));
      } catch (error, stack) {
        _crashReporter.recordError(
          error,
          stack,
          reason: 'Damaged place document ${doc.id} skipped',
        );
      }
    }
    return places;
  }

  PlacesFailure _toFailure(Object error, StackTrace stack) {
    if (error is PlacesFailure) return error;
    if (error is TimeoutException) {
      return PlacesFailure(PlacesFailureType.offline, cause: error);
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
        case 'unauthenticated':
          return PlacesFailure(
            PlacesFailureType.permissionDenied,
            cause: error,
          );
        case 'unavailable':
        case 'deadline-exceeded':
        case 'network-request-failed':
          return PlacesFailure(PlacesFailureType.offline, cause: error);
        case 'invalid-argument':
        case 'out-of-range':
          return PlacesFailure(PlacesFailureType.invalidInput, cause: error);
      }
    }
    _crashReporter.recordError(error, stack, reason: 'Unexpected places error');
    return PlacesFailure(PlacesFailureType.unknown, cause: error);
  }
}
