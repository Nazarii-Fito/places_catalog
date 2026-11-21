# Фрагменти коду для звіту ЛР №6

Усі фрагменти згенеровано з актуальних джерел репозиторію. Код і коментарі в ньому англійською (так задумано), пояснення — українською.

## 1. Моделі даних (завдання 5)

### Лістинг 1 — `PlacePhoto`: три походження фото

Файл: `lib/data/models/place_photo.dart`

`asset` (демо), `local` (файл ще не завантажено), `remote` (у хмарі, з метаданими).

```dart
/// Where a photo's bytes live. It decides how the picture is displayed and
/// whether it still has to be uploaded.
enum PhotoKind {
  /// Bundled demo picture (the seeded catalog). Never uploaded or deleted.
  asset,

  /// A file picked on this device that has not reached cloud storage yet.
  /// It exists only inside the form; it is never written to Firestore.
  local,

  /// Uploaded to cloud storage; [PlacePhoto.location] is its public URL.
  remote,
}

/// A photo attached to a place.
///
/// One class for all three origins ([PhotoKind]) so the UI has a single type
/// to display (`PlaceImageView`) and the form can mix saved and new photos.
/// Only [PhotoKind.remote] photos carry cloud metadata.
class PlacePhoto {
  const PlacePhoto._({
    required this.kind,
    required this.location,
    required this.fileSizeBytes,
    this.storagePath,
    this.contentType,
    this.uploadedAt,
  });

  /// A bundled demo picture.
  const PlacePhoto.asset(String assetPath, {int fileSizeBytes = 0})
    : this._(
        kind: PhotoKind.asset,
        location: assetPath,
        fileSizeBytes: fileSizeBytes,
      );

  /// A device file that is waiting to be uploaded.
  const PlacePhoto.local(
    String filePath, {
    required int fileSizeBytes,
    String? contentType,
  }) : this._(
         kind: PhotoKind.local,
         location: filePath,
         fileSizeBytes: fileSizeBytes,
         contentType: contentType,
       );

  /// A file already in cloud storage.
  const PlacePhoto.remote({
    required String url,
    required String storagePath,
    required int fileSizeBytes,
    required String contentType,
    required DateTime uploadedAt,
  }) : this._(
         kind: PhotoKind.remote,
         location: url,
         fileSizeBytes: fileSizeBytes,
         storagePath: storagePath,
         contentType: contentType,
         uploadedAt: uploadedAt,
       );

  /// Reads the map written by [toJson]. Also accepts the Lab 5 format
  /// (`imageAsset` + `fileSizeBytes`) so saved local catalogs keep working.
  factory PlacePhoto.fromJson(Map<String, Object?> json) {
    final String? legacyAsset = json['imageAsset'] as String?;
    if (legacyAsset != null) {
      return PlacePhoto.asset(
        legacyAsset,
        fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      );
    }
    final PhotoKind kind = PhotoKind.values.byName(json['kind'] as String);
    final int size = (json['fileSizeBytes'] as num?)?.toInt() ?? 0;
    switch (kind) {
      case PhotoKind.asset:
        return PlacePhoto.asset(
          json['location'] as String,
          fileSizeBytes: size,
        );
      case PhotoKind.local:
        return PlacePhoto.local(
          json['location'] as String,
          fileSizeBytes: size,
          contentType: json['contentType'] as String?,
        );
      case PhotoKind.remote:
        return PlacePhoto.remote(
          url: json['location'] as String,
          storagePath: json['storagePath'] as String,
          fileSizeBytes: size,
          contentType: json['contentType'] as String,
          uploadedAt: DateTime.parse(json['uploadedAt'] as String),
        );
    }
  }

  final PhotoKind kind;

  /// Asset path, local file path or public URL, depending on [kind].
  final String location;
  final int fileSizeBytes;

  /// Object path inside the bucket (`users/<uid>/<placeId>/<file>`);
  /// `null` unless the photo is remote. Needed to delete the file later.
  final String? storagePath;
  final String? contentType;
  final DateTime? uploadedAt;

  bool get isRemote => kind == PhotoKind.remote;
  bool get isLocal => kind == PhotoKind.local;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'location': location,
    'fileSizeBytes': fileSizeBytes,
    'storagePath': storagePath,
    'contentType': contentType,
    'uploadedAt': uploadedAt?.toIso8601String(),
  };

  /// Two photos are the same when they point at the same bytes.
  @override
  bool operator ==(Object other) =>
      other is PlacePhoto && other.kind == kind && other.location == location;

  @override
  int get hashCode => Object.hash(kind, location);
}
```

### Лістинг 2 — `PlaceMapper`: заклад ↔ документ Firestore

Файл: `lib/data/firestore/place_mapper.dart`

Мапи містять лише типи Dart; `DateTime` ↔ `Timestamp` конвертує сховище на межі SDK.

```dart
import '../models/place.dart';
import '../models/place_category.dart';
import '../models/place_photo.dart';
import '../models/review.dart';

/// Converts a [Place] to and from the plain map stored in a Firestore
/// document (`users/{uid}/places/{placeId}`).
///
/// The maps contain only Dart types (`DateTime`, `num`, `List`, `Map`): the
/// Firestore store turns `DateTime` into `Timestamp` at the very edge, so
/// this mapper (and the repository logic above it) can be tested without
/// the SDK.
///
/// * `review` is embedded in the place document: it is 1:1 with the place and
///   always read together with it.
/// * `photos` is an array (max 5), not a sub-collection: one read returns the
///   whole place and the small limit keeps the document tiny.
/// * A photo that is still a local file never reaches Firestore: files are
///   uploaded first, only their metadata is stored.
abstract final class PlaceMapper {
  static Map<String, Object?> toMap(Place place) {
    final Review? review = place.review;
    return {
      'name': place.name,
      'category': place.category.name,
      'subtitle': place.subtitle,
      'address': place.address,
      'latitude': place.latitude,
      'longitude': place.longitude,
      'visitDate': place.visitDate,
      'isFavorite': place.isFavorite,
      'cover': _photoToMap(place.coverImage),
      'review': review == null ? null : _reviewToMap(review),
      'photos': [for (final PlacePhoto p in place.photos) _photoToMap(p)],
      // Only an existing record carries its creation time; for a new one the
      // store stamps it with the server time.
      if (place.createdAt != null) 'createdAt': place.createdAt,
    };
  }

  /// Builds a [Place] from document [data]. Throws if the data is damaged
  /// (missing field, unknown category) so the caller can report it.
  static Place fromMap(String id, Map<String, Object?> data) {
    final Object? review = data['review'];
    return Place(
      id: id,
      name: data['name']! as String,
      category: PlaceCategory.values.byName(data['category']! as String),
      subtitle: data['subtitle'] as String? ?? '',
      address: data['address'] as String? ?? '',
      visitDate: data['visitDate']! as DateTime,
      coverImage: _photoFromMap(_map(data['cover'])),
      createdAt: data['createdAt'] as DateTime?,
      review: review == null ? null : _reviewFromMap(_map(review)),
      isFavorite: data['isFavorite'] as bool? ?? false,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      photos: [
        for (final Object? p in data['photos'] as List<Object?>? ?? const [])
          _photoFromMap(_map(p)),
      ],
    );
  }

  static Map<String, Object?> _map(Object? raw) =>
      (raw! as Map<Object?, Object?>).cast<String, Object?>();

  static Map<String, Object?> _photoToMap(PlacePhoto photo) {
    if (photo.isLocal) {
      throw StateError('A local photo must be uploaded before it is saved.');
    }
    return {
      'kind': photo.kind.name,
      'url': photo.location,
      'storagePath': photo.storagePath,
      'sizeBytes': photo.fileSizeBytes,
      'contentType': photo.contentType,
      'uploadedAt': photo.uploadedAt,
    };
  }

  static PlacePhoto _photoFromMap(Map<String, Object?> map) {
    final int size = (map['sizeBytes'] as num?)?.toInt() ?? 0;
    final String url = map['url']! as String;
    switch (PhotoKind.values.byName(map['kind']! as String)) {
      case PhotoKind.asset:
        return PlacePhoto.asset(url, fileSizeBytes: size);
      case PhotoKind.remote:
        return PlacePhoto.remote(
          url: url,
          storagePath: map['storagePath']! as String,
          fileSizeBytes: size,
          contentType: map['contentType']! as String,
          uploadedAt: map['uploadedAt']! as DateTime,
        );
      case PhotoKind.local:
        throw StateError('A local photo cannot be stored.');
    }
  }

  static Map<String, Object?> _reviewToMap(Review r) => {
    'overallRating': r.overallRating,
    'foodRating': r.foodRating,
    'serviceRating': r.serviceRating,
    'atmosphereRating': r.atmosphereRating,
    'textNote': r.textNote,
    'tags': r.tags,
    'updatedAt': r.updatedAt,
  };

  static Review _reviewFromMap(Map<String, Object?> m) => Review(
    overallRating: (m['overallRating']! as num).toDouble(),
    foodRating: (m['foodRating'] as num?)?.toDouble(),
    serviceRating: (m['serviceRating'] as num?)?.toDouble(),
    atmosphereRating: (m['atmosphereRating'] as num?)?.toDouble(),
    textNote: m['textNote'] as String? ?? '',
    tags: [
      ...(m['tags'] as List<Object?>? ?? const <Object?>[]).cast<String>(),
    ],
    updatedAt: m['updatedAt'] as DateTime?,
  );
}
```

## 2. Репозиторій Firestore (завдання 5)

### Лістинг 3 — Інтерфейс `PlacesRepository`

Файл: `lib/data/repositories/places_repository.dart`

```dart
import '../models/place.dart';

/// One page of the catalog plus the position to continue from.
class PlacesPage {
  const PlacesPage({required this.places, this.cursor});

  final List<Place> places;

  /// Opaque position of the last item; pass it back to `loadPage` for the
  /// next page. `null` means there is nothing more to load.
  final Object? cursor;

  bool get hasMore => cursor != null;
}

/// Where the catalog of one user lives.
///
/// An interface (not a concrete class) so the BLoC depends only on *what*
/// is stored, never on *how*: the app uses Cloud Firestore (or a JSON file
/// with `PLACES_BACKEND=local`), tests and the screenshot mode use memory.
/// The uid is a parameter, not a constructor argument, because the
/// repository is created before anybody signs in.
abstract interface class PlacesRepository {
  /// The whole catalog of [uid], re-emitted whenever it changes — also when
  /// the change comes from another device. Seeds the demo catalog on the
  /// first run. Sorted by visit date (newest first).
  Stream<List<Place>> watchPlaces(String uid);

  /// A single read of the whole catalog (same order as [watchPlaces]).
  Future<List<Place>> loadPlaces(String uid);

  /// One page of [perPage] places, for lists too long to load at once.
  /// Pass the previous page's `cursor` to continue.
  Future<PlacesPage> loadPage(String uid, {int perPage = 20, Object? cursor});

  /// A new unique id for a place, available before the place is saved, so
  /// photos can be uploaded under `<placeId>/` first.
  String newPlaceId(String uid);

  /// Inserts a new place or replaces the one with the same id.
  Future<void> savePlace(String uid, Place place);

  Future<void> deletePlace(String uid, String placeId);
}
```

### Лістинг 4 — Тонкий шар `PlacesDocumentStore`

Файл: `lib/data/firestore/places_document_store.dart`

```dart
/// A stored place document: its id and its fields as a plain map.
class PlaceDoc {
  const PlaceDoc(this.id, this.data, {this.cursor});

  final String id;
  final Map<String, Object?> data;

  /// Backend-specific position of this document, used to continue paging.
  final Object? cursor;
}

/// The thin layer between the repository and the document database.
///
/// It only moves maps in and out and knows nothing about [Place]. That keeps
/// the SDK in exactly one small class (`FirestorePlacesDocumentStore`) and
/// lets the repository logic — seeding once, sorting, error mapping,
/// write timeout — be tested against `InMemoryPlacesDocumentStore`.
abstract interface class PlacesDocumentStore {
  /// A new unique document id (generated locally, no network).
  String newId(String uid);

  /// Every place of [uid], ordered by `visitDate` (newest first), re-emitted
  /// on each change.
  Stream<List<PlaceDoc>> watch(String uid);

  /// Up to [limit] places ordered like [watch], after the [after] cursor.
  Future<List<PlaceDoc>> fetchPage(
    String uid, {
    required int limit,
    Object? after,
  });

  /// Writes the document. `createdAt` is added when [data] has none;
  /// `updatedAt` is always set to the time of the write.
  Future<void> set(String uid, String id, Map<String, Object?> data);

  Future<void> delete(String uid, String id);

  /// Writes [places] and marks the user as seeded, **atomically and only if
  /// the user was not seeded before**. Returns whether this call seeded.
  /// The flag is what stops the demo catalog from coming back after the user
  /// deletes everything.
  Future<bool> seedOnce(String uid, List<PlaceDoc> places);
}
```

### Лістинг 5 — `FirestorePlacesDocumentStore` (єдине місце, де є SDK)

Файл: `lib/data/firestore/firestore_places_document_store.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'places_document_store.dart';

/// [PlacesDocumentStore] on Cloud Firestore: `users/{uid}/places/{id}`.
///
/// The only class that touches the SDK. `DateTime` ↔ `Timestamp` is
/// converted here so the rest of the code stays SDK-free.
class FirestorePlacesDocumentStore implements PlacesDocumentStore {
  FirestorePlacesDocumentStore(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _places(String uid) =>
      _user(uid).collection('places');

  /// Ordered by visit date only: a single-field order needs no composite
  /// index. Ties are broken by the repository (createdAt, id).
  Query<Map<String, dynamic>> _ordered(String uid) =>
      _places(uid).orderBy('visitDate', descending: true);

  @override
  String newId(String uid) => _places(uid).doc().id;

  @override
  Stream<List<PlaceDoc>> watch(String uid) {
    return _ordered(uid).snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) => [
        for (final QueryDocumentSnapshot<Map<String, dynamic>> d
            in snapshot.docs)
          PlaceDoc(d.id, _fromFirestore(d.data()), cursor: d),
      ],
    );
  }

  @override
  Future<List<PlaceDoc>> fetchPage(
    String uid, {
    required int limit,
    Object? after,
  }) async {
    Query<Map<String, dynamic>> query = _ordered(uid).limit(limit);
    if (after is DocumentSnapshot) query = query.startAfterDocument(after);
    final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
    return [
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d in snapshot.docs)
        PlaceDoc(d.id, _fromFirestore(d.data()), cursor: d),
    ];
  }

  @override
  Future<void> set(String uid, String id, Map<String, Object?> data) {
    final Map<String, Object?> body = {
      ..._toFirestore(data),
      // The server's clock, not the phone's: ordering stays trustworthy.
      'createdAt': data['createdAt'] == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(data['createdAt']! as DateTime),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    return _places(uid).doc(id).set(body);
  }

  @override
  Future<void> delete(String uid, String id) => _places(uid).doc(id).delete();

  @override
  Future<bool> seedOnce(String uid, List<PlaceDoc> places) {
    return _db.runTransaction<bool>((Transaction tx) async {
      final DocumentSnapshot<Map<String, dynamic>> user = await tx.get(
        _user(uid),
      );
      if (user.data()?['seededAt'] != null) return false;
      for (final PlaceDoc doc in places) {
        tx.set(_places(uid).doc(doc.id), {
          ..._toFirestore(doc.data),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      tx.set(_user(uid), {
        'seededAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    });
  }

  // ---- DateTime <-> Timestamp, recursively -------------------------------

  static Object? _convertOut(Object? value) {
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is Map) {
      return {
        for (final MapEntry<dynamic, dynamic> e in value.entries)
          e.key: _convertOut(e.value),
      };
    }
    if (value is List) return [for (final Object? v in value) _convertOut(v)];
    return value;
  }

  static Object? _convertIn(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is Map) {
      return {
        for (final MapEntry<dynamic, dynamic> e in value.entries)
          e.key: _convertIn(e.value),
      };
    }
    if (value is List) return [for (final Object? v in value) _convertIn(v)];
    return value;
  }

  static Map<String, Object?> _toFirestore(Map<String, Object?> data) => {
    for (final MapEntry<String, Object?> e in data.entries)
      e.key: _convertOut(e.value),
  };

  static Map<String, Object?> _fromFirestore(Map<String, dynamic> data) => {
    for (final MapEntry<String, dynamic> e in data.entries)
      e.key: _convertIn(e.value),
  };
}
```

### Лістинг 6 — `FirestorePlacesRepository`

Файл: `lib/data/repositories/firestore_places_repository.dart`

Засів один раз, живий потік, порядок, типізовані помилки, таймаут запису (офлайн).

```dart
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
```

### Лістинг 7 — `PlacesFailure`: типізовані помилки

Файл: `lib/core/errors/places_failure.dart`

```dart
import '../constants/app_strings.dart';

/// Kinds of catalog (cloud database / storage) errors the UI distinguishes.
enum PlacesFailureType {
  /// Security rules refused the request (signed out, wrong user).
  permissionDenied,

  /// No connection or the service is unreachable right now.
  offline,

  /// Cloud file storage is not set up (no Supabase keys in this build).
  storageNotConfigured,

  /// The record or the file does not satisfy a size/type/count limit.
  invalidInput,

  unknown,
}

/// A catalog operation failed. Repositories translate SDK exceptions
/// (`FirebaseException`, `StorageException`, `DioException`…) into this one
/// type, so BLoCs and screens never import an SDK to understand an error.
class PlacesFailure implements Exception {
  const PlacesFailure(this.type, {this.detail, this.cause});

  final PlacesFailureType type;

  /// Extra text for an `invalidInput` failure (e.g. "photo is larger than…").
  final String? detail;

  /// The original error, kept for Crashlytics. Never shown to the user.
  final Object? cause;

  /// Worth offering "Retry": the same request may succeed later.
  bool get isRetryable =>
      type == PlacesFailureType.offline || type == PlacesFailureType.unknown;

  String get message => switch (type) {
    PlacesFailureType.permissionDenied => AppStrings.errorPermissionDenied,
    PlacesFailureType.offline => AppStrings.errorOffline,
    PlacesFailureType.storageNotConfigured => AppStrings.errorStorageNotSetUp,
    PlacesFailureType.invalidInput => detail ?? AppStrings.errorInvalidInput,
    PlacesFailureType.unknown => AppStrings.errorUnknown,
  };

  @override
  String toString() => 'PlacesFailure($type, $detail, $cause)';
}
```

### Лістинг 8 — Правила Firestore (завдання 4)

Файл: `firestore.rules`

```dart
rules_version = '2';

// PlacesCatalog is a PERSONAL diary: every user reads and writes only their
// own data. (The course example lets everybody read what an author
// publishes; that does not fit private visit notes. See docs/decisions.md.)
service cloud.firestore {
  match /databases/{database}/documents {

    function signedInAs(uid) {
      return request.auth != null && request.auth.uid == uid;
    }

    function validPhoto(photo) {
      return photo is map
          && photo.kind in ['asset', 'remote']
          && photo.url is string;
    }

    // A place document written by the app. `latitude` / `longitude` are
    // numbers, or null for a place without a picked location.
    function validPlace(place) {
      return place.keys().hasAll(
               ['name', 'category', 'address', 'visitDate', 'isFavorite',
                'cover', 'photos'])
          && place.name is string
          && place.name.size() >= 2 && place.name.size() <= 50
          && place.category in ['cafe', 'restaurant', 'bar', 'museum',
                                'fastFood', 'hotel', 'bakery', 'pub']
          && place.address is string
          && place.visitDate is timestamp
          && place.isFavorite is bool
          && (place.get('latitude', null) == null
              || place.latitude is number)
          && (place.get('longitude', null) == null
              || place.longitude is number)
          && validPhoto(place.cover)
          && place.photos is list
          && place.photos.size() <= 5
          && (place.get('review', null) == null || place.review is map);
    }

    match /users/{uid} {
      allow read: if signedInAs(uid);
      // The profile mirror and the `seededAt` flag. Never deleted by the app.
      allow create, update: if signedInAs(uid);
      allow delete: if false;

      match /places/{placeId} {
        allow read, delete: if signedInAs(uid);
        allow create, update: if signedInAs(uid) && validPlace(request.resource.data);
      }
    }

    // Everything else is closed.
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## 3. Використання репозиторію для списків (завдання 6)

### Лістинг 9 — `PlacesBloc` на живому потоці

Файл: `lib/features/places/bloc/places_bloc.dart`

Блок підписується на `watchPlaces`; будь-яка зміна (власна чи з іншого пристрою) приходить потоком.

```dart
// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/places_failure.dart';
import '../../../data/models/place.dart';
import '../../../data/models/place_photo.dart';
import '../../../data/repositories/media_repository.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/crash_reporter.dart';

part 'places_event.dart';
part 'places_state.dart';

/// Owns the catalog of one signed-in user (app state shared by Home,
/// Favorites, Details and Profile).
///
/// Cycle: the UI adds a [PlacesEvent] → the handler talks to the
/// [PlacesRepository] → the repository's **live stream** reports the new
/// list → `emit` publishes a new [PlacesState] → `BlocBuilder`s rebuild.
/// The list is never edited in place, and the bloc never assumes a write
/// "worked": it shows what the repository says is stored, so a change from
/// another device appears the same way as the user's own.
///
/// One instance per uid: it is created with the user in `UserScope`, so
/// switching accounts drops this state and one user's catalog can never
/// leak to the next.
class PlacesBloc extends Bloc<PlacesEvent, PlacesState> {
  PlacesBloc({
    required this.uid,
    required PlacesRepository repository,
    required AnalyticsService analytics,
    required MediaRepository media,
    required CrashReporter crashReporter,
  }) : _repository = repository,
       _media = media,
       _analytics = analytics,
       _crashReporter = crashReporter,
       super(const PlacesState()) {
    on<PlacesLoadRequested>(_onLoad);
    on<_PlacesArrived>(_onArrived);
    on<_PlacesStreamFailed>(_onStreamFailed);
    on<PlaceDeleted>(_onDeleted);
    on<PlaceFavoriteToggled>(_onFavoriteToggled);
    on<PlaceOpened>(_onOpened);
  }

  final String uid;
  final PlacesRepository _repository;
  final MediaRepository _media;
  final AnalyticsService _analytics;
  final CrashReporter _crashReporter;

  StreamSubscription<List<Place>>? _subscription;

  /// (Re)subscribes to the catalog. Sent at start and by "Retry".
  Future<void> _onLoad(
    PlacesLoadRequested event,
    Emitter<PlacesState> emit,
  ) async {
    emit(state.copyWith(status: PlacesStatus.loading, clearError: true));
    // Not awaited: the old stream is simply dropped (nothing depends on the
    // moment its cancellation completes).
    unawaited(_subscription?.cancel());
    _subscription = _repository
        .watchPlaces(uid)
        .listen(
          (List<Place> places) => add(_PlacesArrived(places)),
          onError: (Object error, StackTrace stack) =>
              add(_PlacesStreamFailed(error, stack)),
        );
  }

  void _onArrived(_PlacesArrived event, Emitter<PlacesState> emit) {
    emit(
      state.copyWith(
        status: PlacesStatus.loaded,
        places: event.places,
        // A fresh list also ends an earlier "could not save" notice.
        clearError: true,
      ),
    );
  }

  Future<void> _onStreamFailed(
    _PlacesStreamFailed event,
    Emitter<PlacesState> emit,
  ) async {
    await _crashReporter.recordError(
      event.error,
      event.stack,
      reason: 'Watch places',
    );
    emit(
      state.copyWith(
        status: PlacesStatus.failure,
        errorMessage: event.error is PlacesFailure
            ? (event.error as PlacesFailure).message
            : AppStrings.placesLoadError,
      ),
    );
  }

  Future<void> _onFavoriteToggled(
    PlaceFavoriteToggled event,
    Emitter<PlacesState> emit,
  ) async {
    final Place? place = state.byId(event.placeId);
    if (place == null) return;
    final Place toggled = place.copyWith(isFavorite: !place.isFavorite);
    if (await _save(emit, toggled)) {
      _analytics.logPlaceFavoriteToggled(
        placeId: toggled.id,
        isFavorite: toggled.isFavorite,
      );
    }
  }

  Future<void> _onDeleted(PlaceDeleted event, Emitter<PlacesState> emit) async {
    final Place? place = state.byId(event.placeId);
    emit(state.copyWith(clearError: true));
    try {
      await _repository.deletePlace(uid, event.placeId);
      // No emit: the live stream delivers the shorter list.
    } catch (error, stack) {
      await _failSave(emit, error, stack);
      return; // the record is still there, so keep its files
    }
    // The record is gone; now its files. Best-effort: a failure leaves
    // orphan files (logged), it must not bring the deleted place back.
    if (place != null) await _deleteFiles(place);
  }

  Future<void> _deleteFiles(Place place) async {
    final List<String> paths = [
      for (final PlacePhoto p in place.photos)
        if (p.storagePath != null) p.storagePath!,
    ];
    if (paths.isEmpty) return;
    try {
      await _media.deleteAll(paths);
    } catch (error, stack) {
      await _crashReporter.recordError(
        error,
        stack,
        reason: 'Deleting files of a deleted place failed (orphans)',
      );
    }
  }

  void _onOpened(PlaceOpened event, Emitter<PlacesState> emit) {
    final Place? place = state.byId(event.placeId);
    if (place == null) return;
    _analytics.logPlaceOpened(placeId: place.id, category: place.category.name);
  }

  /// Writes [place]; the screen updates when the stream reports it.
  /// Returns whether the write was accepted.
  Future<bool> _save(Emitter<PlacesState> emit, Place place) async {
    emit(state.copyWith(clearError: true));
    try {
      await _repository.savePlace(uid, place);
      return true;
    } catch (error, stack) {
      await _failSave(emit, error, stack);
      return false;
    }
  }

  Future<void> _failSave(
    Emitter<PlacesState> emit,
    Object error,
    StackTrace stack,
  ) async {
    await _crashReporter.recordError(error, stack, reason: 'Save place');
    emit(
      state.copyWith(
        errorMessage: error is PlacesFailure
            ? error.message
            : AppStrings.placesSaveError,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
```

## 4. Create / Update під керуванням BLoC (завдання 7)

### Лістинг 10 — `CreatePlaceBloc`: події

Файл: `lib/features/places/bloc/create_place_event.dart`

```dart
part of 'create_place_bloc.dart';

sealed class CreatePlaceEvent extends Equatable {
  const CreatePlaceEvent();

  @override
  List<Object?> get props => const [];
}

/// Save a new place. [draft] comes from the form: its `photos` may include
/// local files that still have to be uploaded; its `id` is ignored (the bloc
/// allocates the real one first, because photos are stored under it).
final class CreatePlaceSubmitted extends CreatePlaceEvent {
  const CreatePlaceSubmitted(this.draft);

  final Place draft;

  @override
  List<Object?> get props => [draft];
}

/// Forget the last result (a form was opened).
final class CreatePlaceReset extends CreatePlaceEvent {
  const CreatePlaceReset();
}
```

### Лістинг 11 — `CreatePlaceBloc`: стани

Файл: `lib/features/places/bloc/create_place_state.dart`

```dart
part of 'create_place_bloc.dart';

sealed class CreatePlaceState extends Equatable {
  const CreatePlaceState();

  @override
  List<Object?> get props => const [];
}

final class CreatePlaceIdle extends CreatePlaceState {
  const CreatePlaceIdle();
}

/// Saving is in progress: [uploaded] of [total] photos are in storage.
/// The form disables Save and shows "Uploading 2 of 4".
final class PlaceCreatingState extends CreatePlaceState {
  const PlaceCreatingState({this.uploaded = 0, this.total = 0});

  final int uploaded;
  final int total;

  @override
  List<Object?> get props => [uploaded, total];
}

final class PlaceCreateErrorState extends CreatePlaceState {
  const PlaceCreateErrorState({required this.message, required this.retryable});

  final String message;

  /// The same request may work later (no network); false for "storage not
  /// configured" or a rejected file.
  final bool retryable;

  @override
  List<Object?> get props => [message, retryable];
}

final class PlaceCreateSuccessState extends CreatePlaceState {
  const PlaceCreateSuccessState(this.place);

  final Place place;

  @override
  List<Object?> get props => [place];
}
```

### Лістинг 12 — `CreatePlaceBloc`

Файл: `lib/features/places/bloc/create_place_bloc.dart`

```dart
// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/places_failure.dart';
import '../../../data/models/place.dart';
import '../../../data/models/place_photo.dart';
import '../../../data/repositories/media_repository.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/services/crash_reporter.dart';
import '../../../data/services/photo_upload_session.dart';

part 'create_place_event.dart';
part 'create_place_state.dart';

/// Creates a place: **id → photos to storage → document to the database**.
///
/// Order matters. The id is allocated first because the photos are stored
/// under `users/<uid>/<placeId>/`. The document is written last and only
/// with the final photo URLs, so there is never a record pointing at files
/// that failed to upload. If anything fails after some photos are already
/// uploaded, those files are deleted again (rollback) and the error is
/// reported; the user can retry.
class CreatePlaceBloc extends Bloc<CreatePlaceEvent, CreatePlaceState> {
  CreatePlaceBloc({
    required this.uid,
    required PlacesRepository repository,
    required MediaRepository media,
    required CrashReporter crashReporter,
  }) : _repository = repository,
       _media = media,
       _crashReporter = crashReporter,
       super(const CreatePlaceIdle()) {
    on<CreatePlaceSubmitted>(_onSubmitted);
    on<CreatePlaceReset>((_, Emitter<CreatePlaceState> emit) {
      // Never wipe a save that is still running.
      if (state is! PlaceCreatingState) emit(const CreatePlaceIdle());
    });
  }

  final String uid;
  final PlacesRepository _repository;
  final MediaRepository _media;
  final CrashReporter _crashReporter;

  Future<void> _onSubmitted(
    CreatePlaceSubmitted event,
    Emitter<CreatePlaceState> emit,
  ) async {
    // A second tap while saving must not start a second save.
    if (state is PlaceCreatingState) return;
    final int total = event.draft.photos
        .where((PlacePhoto p) => p.isLocal)
        .length;
    emit(PlaceCreatingState(total: total));

    final String placeId = _repository.newPlaceId(uid);
    final PhotoUploadSession session = PhotoUploadSession(
      media: _media,
      crashReporter: _crashReporter,
      uid: uid,
      placeId: placeId,
    );
    try {
      final List<PlacePhoto> photos = await session.upload(
        event.draft.photos,
        onProgress: (int uploaded, int total) {
          if (!isClosed) {
            emit(PlaceCreatingState(uploaded: uploaded, total: total));
          }
        },
      );
      final Place place = event.draft.copyWith(
        id: placeId,
        photos: photos,
        // The card thumbnail is the first photo, now its uploaded copy.
        coverImage: photos.isNotEmpty ? photos.first : null,
      );
      await _repository.savePlace(uid, place);
      emit(PlaceCreateSuccessState(place));
    } on PlacesFailure catch (failure) {
      await session.rollback();
      emit(
        PlaceCreateErrorState(
          message: failure.message,
          retryable: failure.isRetryable,
        ),
      );
    } catch (error, stack) {
      await session.rollback();
      await _crashReporter.recordError(error, stack, reason: 'Create place');
      emit(
        PlaceCreateErrorState(
          message: const PlacesFailure(PlacesFailureType.unknown).message,
          retryable: true,
        ),
      );
    }
  }
}
```

### Лістинг 13 — `UpdatePlaceBloc`: події

Файл: `lib/features/places/bloc/update_place_event.dart`

```dart
part of 'update_place_bloc.dart';

/// Which screen started the update, so only that screen reports its result
/// (the Place form and the notes/tags editor on Details share the bloc).
enum UpdateOrigin { form, inline }

sealed class UpdatePlaceEvent extends Equatable {
  const UpdatePlaceEvent();

  @override
  List<Object?> get props => const [];
}

/// Save the edited place. [original] is what is stored now; [draft] is the
/// wanted result. Comparing them tells which photos are kept, new (local
/// files to upload) and removed (to delete from storage afterwards).
final class UpdatePlaceSubmitted extends UpdatePlaceEvent {
  const UpdatePlaceSubmitted({
    required this.original,
    required this.draft,
    this.origin = UpdateOrigin.form,
  });

  final Place original;
  final Place draft;
  final UpdateOrigin origin;

  @override
  List<Object?> get props => [original, draft, origin];
}

final class UpdatePlaceReset extends UpdatePlaceEvent {
  const UpdatePlaceReset();
}
```

### Лістинг 14 — `UpdatePlaceBloc`: стани

Файл: `lib/features/places/bloc/update_place_state.dart`

```dart
part of 'update_place_bloc.dart';

sealed class UpdatePlaceState extends Equatable {
  const UpdatePlaceState();

  @override
  List<Object?> get props => const [];
}

final class UpdatePlaceIdle extends UpdatePlaceState {
  const UpdatePlaceIdle();
}

final class PlaceUpdatingState extends UpdatePlaceState {
  const PlaceUpdatingState({
    this.uploaded = 0,
    this.total = 0,
    this.origin = UpdateOrigin.form,
  });

  final int uploaded;
  final int total;
  final UpdateOrigin origin;

  @override
  List<Object?> get props => [uploaded, total, origin];
}

final class PlaceUpdateErrorState extends UpdatePlaceState {
  const PlaceUpdateErrorState({
    required this.message,
    required this.retryable,
    required this.origin,
  });

  final String message;
  final bool retryable;
  final UpdateOrigin origin;

  @override
  List<Object?> get props => [message, retryable, origin];
}

final class PlaceUpdateSuccessState extends UpdatePlaceState {
  const PlaceUpdateSuccessState(this.place, {required this.origin});

  final Place place;
  final UpdateOrigin origin;

  @override
  List<Object?> get props => [place, origin];
}
```

### Лістинг 15 — `UpdatePlaceBloc`

Файл: `lib/features/places/bloc/update_place_bloc.dart`

```dart
// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/places_failure.dart';
import '../../../data/models/place.dart';
import '../../../data/models/place_photo.dart';
import '../../../data/repositories/media_repository.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/services/crash_reporter.dart';
import '../../../data/services/photo_upload_session.dart';

part 'update_place_event.dart';
part 'update_place_state.dart';

/// Saves an edited place: **new photos to storage → document → delete the
/// removed photos' files**.
///
/// * Unchanged photos are kept as they are — never uploaded again.
/// * New photos (local files) are uploaded first; if the document write then
///   fails, they are rolled back, so nothing is half-saved.
/// * Files of removed photos are deleted only *after* the document no longer
///   references them. That delete is best-effort: a failure leaves an
///   orphan file (logged) but never fails the user's save.
class UpdatePlaceBloc extends Bloc<UpdatePlaceEvent, UpdatePlaceState> {
  UpdatePlaceBloc({
    required this.uid,
    required PlacesRepository repository,
    required MediaRepository media,
    required CrashReporter crashReporter,
  }) : _repository = repository,
       _media = media,
       _crashReporter = crashReporter,
       super(const UpdatePlaceIdle()) {
    on<UpdatePlaceSubmitted>(_onSubmitted);
    on<UpdatePlaceReset>((_, Emitter<UpdatePlaceState> emit) {
      if (state is! PlaceUpdatingState) emit(const UpdatePlaceIdle());
    });
  }

  final String uid;
  final PlacesRepository _repository;
  final MediaRepository _media;
  final CrashReporter _crashReporter;

  Future<void> _onSubmitted(
    UpdatePlaceSubmitted event,
    Emitter<UpdatePlaceState> emit,
  ) async {
    if (state is PlaceUpdatingState) return;
    final UpdateOrigin origin = event.origin;
    final int total = event.draft.photos
        .where((PlacePhoto p) => p.isLocal)
        .length;
    emit(PlaceUpdatingState(total: total, origin: origin));

    final PhotoUploadSession session = PhotoUploadSession(
      media: _media,
      crashReporter: _crashReporter,
      uid: uid,
      placeId: event.original.id,
    );
    try {
      final List<PlacePhoto> photos = await session.upload(
        event.draft.photos,
        onProgress: (int uploaded, int total) {
          if (!isClosed) {
            emit(
              PlaceUpdatingState(
                uploaded: uploaded,
                total: total,
                origin: origin,
              ),
            );
          }
        },
      );
      final Place place = event.draft.copyWith(
        id: event.original.id,
        photos: photos,
        coverImage: photos.isNotEmpty ? photos.first : null,
      );
      await _repository.savePlace(uid, place);
      emit(PlaceUpdateSuccessState(place, origin: origin));
      await _deleteRemoved(event.original, place);
    } on PlacesFailure catch (failure) {
      await session.rollback();
      emit(
        PlaceUpdateErrorState(
          message: failure.message,
          retryable: failure.isRetryable,
          origin: origin,
        ),
      );
    } catch (error, stack) {
      await session.rollback();
      await _crashReporter.recordError(error, stack, reason: 'Update place');
      emit(
        PlaceUpdateErrorState(
          message: const PlacesFailure(PlacesFailureType.unknown).message,
          retryable: true,
          origin: origin,
        ),
      );
    }
  }

  /// Deletes the stored files the saved place no longer references.
  Future<void> _deleteRemoved(Place original, Place saved) async {
    final Set<String> kept = {
      for (final PlacePhoto p in saved.photos)
        if (p.storagePath != null) p.storagePath!,
    };
    final List<String> removed = [
      for (final PlacePhoto p in original.photos)
        if (p.storagePath != null && !kept.contains(p.storagePath))
          p.storagePath!,
    ];
    if (removed.isEmpty) return;
    try {
      await _media.deleteAll(removed);
    } catch (error, stack) {
      await _crashReporter.recordError(
        error,
        stack,
        reason: 'Deleting ${removed.length} removed photos failed (orphans)',
      );
    }
  }
}
```

### Лістинг 16 — `PhotoUploadSession`: завантаження з відкатом

Файл: `lib/data/services/photo_upload_session.dart`

```dart
// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import '../../core/errors/places_failure.dart';
import '../models/place_photo.dart';
import '../repositories/media_repository.dart';
import 'crash_reporter.dart';

/// One save operation's uploads: sends the not-yet-uploaded photos of a
/// place to cloud storage **one after another**, remembers what it
/// uploaded, and can take it all back.
///
/// The rollback is why this is an object and not a function: if the 3rd of 4
/// uploads fails, the 2 files already in storage belong to a place that will
/// not be saved, so they are deleted (best-effort) instead of piling up as
/// orphans. Shared by `CreatePlaceBloc` and `UpdatePlaceBloc`.
class PhotoUploadSession {
  PhotoUploadSession({
    required MediaRepository media,
    required CrashReporter crashReporter,
    required this.uid,
    required this.placeId,
  }) : _media = media,
       _crashReporter = crashReporter;

  final MediaRepository _media;
  final CrashReporter _crashReporter;
  final String uid;
  final String placeId;

  final List<String> _uploadedPaths = [];

  /// How many files this session has uploaded so far.
  int get uploadedCount => _uploadedPaths.length;

  /// Returns [photos] in the same order with every [PhotoKind.local] one
  /// replaced by its uploaded copy. Assets and already uploaded photos are
  /// kept as they are (never re-uploaded). [onProgress] gets
  /// `(uploaded, total)` before each upload and once at the end.
  /// Throws [PlacesFailure] on the first failed upload.
  Future<List<PlacePhoto>> upload(
    List<PlacePhoto> photos, {
    void Function(int uploaded, int total)? onProgress,
  }) async {
    final int total = photos.where((PlacePhoto p) => p.isLocal).length;
    int done = 0;
    final List<PlacePhoto> result = [];
    for (final PlacePhoto photo in photos) {
      if (!photo.isLocal) {
        result.add(photo);
        continue;
      }
      onProgress?.call(done, total);
      final PlacePhoto remote = await _media.uploadPlacePhoto(
        uid: uid,
        placeId: placeId,
        local: photo,
      );
      _uploadedPaths.add(remote.storagePath!);
      done++;
      result.add(remote);
    }
    onProgress?.call(done, total);
    return result;
  }

  /// Deletes everything this session uploaded. Never throws: it runs while
  /// another error is already being reported.
  Future<void> rollback() async {
    if (_uploadedPaths.isEmpty) return;
    try {
      await _media.deleteAll(_uploadedPaths);
    } catch (error, stack) {
      await _crashReporter.recordError(
        error,
        stack,
        reason: 'Rollback of ${_uploadedPaths.length} uploaded photos failed',
      );
    }
  }
}
```

### Лістинг 17 — Відправлення події з форми й стан кнопки

Файл: `lib/features/places/screens/place_form_screen.dart` (фрагмент)

Форма лише збирає чернетку й надсилає подію; стани блока керують спінером, прогресом і банером.

```dart
  void _save() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    final Place draft = _buildPlace();
    // The blocs ignore a second tap while a save is running. Closing the
    // form is the success listener's job.
    final Place? original = widget.initial;
    if (original == null) {
      context.read<CreatePlaceBloc>().add(CreatePlaceSubmitted(draft));
    } else {
      context.read<UpdatePlaceBloc>().add(
        UpdatePlaceSubmitted(original: original, draft: draft),
      );
    }
  }

  /// What the save buttons area shows, from the bloc of the current mode.
  _SaveView _saveView(BuildContext context) {
    if (_isEditing) {
      return switch (context.watch<UpdatePlaceBloc>().state) {
        PlaceUpdatingState(
          origin: UpdateOrigin.form,
          :final uploaded,
          :final total,
        ) =>
          _SaveView.busy(uploaded, total),
        PlaceUpdateErrorState(
          origin: UpdateOrigin.form,
          :final message,
          :final retryable,
        ) =>
          _SaveView.error(message, retryable),
        _ => const _SaveView.idle(),
      };
    }
    return switch (context.watch<CreatePlaceBloc>().state) {
      PlaceCreatingState(:final uploaded, :final total) => _SaveView.busy(
        uploaded,
        total,
      ),
      PlaceCreateErrorState(:final message, :final retryable) =>
        _SaveView.error(message, retryable),
      _ => const _SaveView.idle(),
    };
  }
```

### Лістинг 18 — `PopScope`, `IgnorePointer`, `BlocListener` у формі

Файл: `lib/features/places/screens/place_form_screen.dart` (фрагмент)

Під час збереження форму не можна закрити чи змінити; успіх закриває форму.

```dart
    final _SaveView save = _saveView(context);
    // While saving, the form cannot be left or edited by accident: touches
    // are ignored and the back swipe is blocked until the bloc finishes.
    return PopScope(
      canPop: !save.busy,
      child: IgnorePointer(
        ignoring: save.busy,
        child: MultiBlocListener(
          listeners: [
            BlocListener<CreatePlaceBloc, CreatePlaceState>(
              listenWhen: (_, CreatePlaceState now) =>
                  now is PlaceCreateSuccessState,
              listener: (BuildContext context, _) =>
                  Navigator.of(context).pop(),
            ),
            BlocListener<UpdatePlaceBloc, UpdatePlaceState>(
              listenWhen: (_, UpdatePlaceState now) =>
                  now is PlaceUpdateSuccessState &&
                  now.origin == UpdateOrigin.form,
              listener: (BuildContext context, _) =>
                  Navigator.of(context).pop(),
            ),
          ],
          child: Scaffold(
```

## 5. Файлове сховище (завдання 8; питання 29)

### Лістинг 19 — Інтерфейс `MediaRepository`

Файл: `lib/data/repositories/media_repository.dart`

```dart
import '../../core/errors/places_failure.dart';
import '../models/place_photo.dart';

/// Cloud storage for place photos (the bytes). The metadata and the public
/// URLs live in Firestore, inside the place document — Storage holds files,
/// the database holds what they are and where to find them.
///
/// An interface so BLoCs use it without knowing the provider (Supabase
/// today); tests and the screenshot mode use `FakeMediaRepository`.
abstract interface class MediaRepository {
  /// `false` when no storage keys were supplied to this build.
  bool get isConfigured;

  /// Uploads a [PhotoKind.local] photo to `users/<uid>/<placeId>/<uuid>.<ext>`
  /// and returns it as a [PhotoKind.remote] photo (public URL and metadata).
  /// Throws [PlacesFailure].
  Future<PlacePhoto> uploadPlacePhoto({
    required String uid,
    required String placeId,
    required PlacePhoto local,
  });

  /// Uploads the user's profile picture to `users/<uid>/avatar/<uuid>.<ext>`
  /// and returns it as a [PhotoKind.remote] photo. Throws [PlacesFailure].
  Future<PlacePhoto> uploadAvatar({
    required String uid,
    required PlacePhoto local,
  });

  /// The object path of [url] if it points into *our* bucket, otherwise
  /// `null` (a preset avatar or a link typed by the user is not ours to
  /// delete).
  String? storagePathOf(String url);

  /// Deletes one object. Best-effort callers may ignore the failure.
  Future<void> deletePhoto(String storagePath);

  /// Deletes many objects in one request.
  Future<void> deleteAll(List<String> storagePaths);
}

/// Used when the build has no storage keys: everything that needs the
/// cloud reports it plainly, the rest of the app keeps working.
class NotConfiguredMediaRepository implements MediaRepository {
  const NotConfiguredMediaRepository();

  @override
  bool get isConfigured => false;

  @override
  Future<PlacePhoto> uploadPlacePhoto({
    required String uid,
    required String placeId,
    required PlacePhoto local,
  }) async => throw const PlacesFailure(PlacesFailureType.storageNotConfigured);

  @override
  Future<PlacePhoto> uploadAvatar({
    required String uid,
    required PlacePhoto local,
  }) async => throw const PlacesFailure(PlacesFailureType.storageNotConfigured);

  @override
  String? storagePathOf(String url) => null;

  @override
  Future<void> deletePhoto(String storagePath) async {}

  @override
  Future<void> deleteAll(List<String> storagePaths) async {}
}
```

### Лістинг 20 — `SupabaseMediaRepository`

Файл: `lib/data/repositories/supabase_media_repository.dart`

Файл — у Supabase Storage, а публічний URL і метадані (`storagePath`, `sizeBytes`, `contentType`, `uploadedAt`) повертаються й зберігаються в Firestore.

```dart
// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/places_failure.dart';
import '../models/place_photo.dart';
import '../services/crash_reporter.dart';
import 'media_repository.dart';

/// [MediaRepository] on Supabase Storage (bucket `place-photos`).
///
/// Only Storage is used: no Supabase Auth, no database. The client is
/// created directly (`SupabaseClient`) rather than through
/// `Supabase.initialize`, so there is no global state and no session or
/// deep-link handling we do not need.
class SupabaseMediaRepository implements MediaRepository {
  SupabaseMediaRepository({
    required SupabaseClient client,
    required CrashReporter crashReporter,
    required String bucket,
    Uuid uuid = const Uuid(),
  }) : _bucket = bucket,
       _storage = client.storage.from(bucket),
       _crashReporter = crashReporter,
       _uuid = uuid;

  final String _bucket;
  final StorageFileApi _storage;
  final CrashReporter _crashReporter;
  final Uuid _uuid;

  @override
  bool get isConfigured => true;

  /// `users/<uid>/<placeId>/<uuid>.<ext>` — never the bucket root, so files
  /// of different users and places never mix, and a unique name means two
  /// uploads can never overwrite each other.
  static String buildPath({
    required String uid,
    required String placeId,
    required String fileId,
    required String contentType,
  }) => 'users/$uid/$placeId/$fileId.${extensionFor(contentType)}';

  static String extensionFor(String contentType) => switch (contentType) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => 'jpg',
  };

  @override
  Future<PlacePhoto> uploadPlacePhoto({
    required String uid,
    required String placeId,
    required PlacePhoto local,
  }) => _upload(uid: uid, folder: placeId, local: local);

  /// `users/<uid>/avatar/<uuid>.<ext>`: the profile picture lives next to
  /// the user's places, under its own folder.
  @override
  Future<PlacePhoto> uploadAvatar({
    required String uid,
    required PlacePhoto local,
  }) => _upload(uid: uid, folder: 'avatar', local: local);

  Future<PlacePhoto> _upload({
    required String uid,
    required String folder,
    required PlacePhoto local,
  }) async {
    final String contentType = local.contentType ?? 'image/jpeg';
    final String path = buildPath(
      uid: uid,
      placeId: folder,
      fileId: _uuid.v4(),
      contentType: contentType,
    );
    try {
      await _storage.upload(
        path,
        File(local.location),
        // The type is set explicitly: the bucket only accepts images and
        // the CDN serves the file with this header.
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      );
      return PlacePhoto.remote(
        url: _storage.getPublicUrl(path),
        storagePath: path,
        fileSizeBytes: local.fileSizeBytes,
        contentType: contentType,
        uploadedAt: DateTime.now().toUtc(),
      );
    } catch (error, stack) {
      throw _toFailure(error, stack);
    }
  }

  @override
  String? storagePathOf(String url) {
    final String marker = '/object/public/$_bucket/';
    final int at = url.indexOf(marker);
    return at == -1 ? null : url.substring(at + marker.length);
  }

  @override
  Future<void> deletePhoto(String storagePath) => deleteAll([storagePath]);

  @override
  Future<void> deleteAll(List<String> storagePaths) async {
    if (storagePaths.isEmpty) return;
    try {
      await _storage.remove(storagePaths);
    } catch (error, stack) {
      throw _toFailure(error, stack);
    }
  }

  PlacesFailure _toFailure(Object error, StackTrace stack) {
    if (error is StorageException) {
      switch (error.statusCode) {
        case '400':
        case '413':
        case '415':
          return PlacesFailure(PlacesFailureType.invalidInput, cause: error);
        case '401':
        case '403':
          return PlacesFailure(
            PlacesFailureType.permissionDenied,
            cause: error,
          );
      }
    } else if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException) {
      return PlacesFailure(PlacesFailureType.offline, cause: error);
    }
    _crashReporter.recordError(error, stack, reason: 'Storage request failed');
    return PlacesFailure(PlacesFailureType.unknown, cause: error);
  }
}
```

### Лістинг 21 — Конфігурація через `--dart-define`

Файл: `lib/data/services/supabase_config.dart`

```dart
/// Cloud-storage settings, supplied at build time with `--dart-define`
/// (see `env/supabase.example.json`). Nothing is hardcoded in the repository:
/// the project URL and key come from the developer's own Supabase project.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');

  /// The project's public key ("publishable" key, or the legacy "anon"
  /// key). It is public by design — access is limited by bucket policies —
  /// but it is still kept out of git.
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// The bucket that holds place photos.
  static const String bucket = 'place-photos';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
```

## 6. REST через dio (завдання 9)

### Лістинг 22 — Моделі `GeocodingResult`, `PickedLocation`

Файл: `lib/data/models/geocoding_result.dart`

```dart
import 'place_category.dart';

/// A place found by address search, by looking up a point on the map, or as
/// a venue (cafe, restaurant…) near it.
class GeocodingResult {
  const GeocodingResult({
    required this.displayName,
    required this.title,
    required this.latitude,
    required this.longitude,
    this.category,
  });

  /// Reads one object of Nominatim's `jsonv2` format (`/search` returns a
  /// list of them, `/reverse` a single one). Throws [FormatException] when
  /// the coordinates are missing — Nominatim sends them as *strings*.
  factory GeocodingResult.fromJson(Map<String, Object?> json) {
    final double? lat = double.tryParse('${json['lat']}');
    final double? lon = double.tryParse('${json['lon']}');
    if (lat == null || lon == null) {
      throw const FormatException('Geocoding result without coordinates');
    }
    final String display = (json['display_name'] as String? ?? '').trim();
    final String name = (json['name'] as String? ?? '').trim();
    return GeocodingResult(
      displayName: display,
      // Header of the location card: the object's own name, else the first
      // part of the address ("5 Avenue, Manhattan, …" → "5 Avenue").
      title: name.isNotEmpty ? name : display.split(',').first.trim(),
      latitude: lat,
      longitude: lon,
    );
  }

  /// Full address, e.g. "Empire State Building, 350, 5th Avenue, Midtown…".
  final String displayName;
  final String title;
  final double latitude;
  final double longitude;

  /// Set for venues (a cafe, a museum…): what kind of place it is, so the form
  /// can fill in the category. `null` for plain addresses.
  final PlaceCategory? category;

  bool get isVenue => category != null;
}

/// What the location picker hands back to the place form: a text address
/// plus the point (FR4: "saves the text address and the GPS coordinates").
class PickedLocation {
  const PickedLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.name,
    this.category,
  });

  final String address;
  final double latitude;
  final double longitude;

  /// Only when the user chose a venue on the map: its name and kind. The form
  /// uses them to pre-fill the place name and category.
  final String? name;
  final PlaceCategory? category;
}

/// What the form tells the location picker when it opens: the place's current
/// address, and its point if it has one (old records may not).
class LocationPickerArgs {
  const LocationPickerArgs({
    required this.address,
    this.latitude,
    this.longitude,
  });

  final String address;
  final double? latitude;
  final double? longitude;

  bool get hasPoint => latitude != null && longitude != null;
}
```

### Лістинг 23 — Інтерфейс `GeocodingRepository`

Файл: `lib/data/repositories/geocoding_repository.dart`

```dart
import '../models/geocoding_result.dart';

/// Address search and reverse geocoding. An interface so the location picker
/// does not know which REST service answers (Nominatim today).
abstract interface class GeocodingRepository {
  /// Places matching [query] (best first); empty when nothing is found.
  /// Throws `GeocodingFailure`.
  Future<List<GeocodingResult>> search(String query);

  /// The place at the point, or `null` when the point has no address (open
  /// water, desert). Throws `GeocodingFailure`.
  Future<GeocodingResult?> reverse(double latitude, double longitude);
}

/// Scripted geocoder for tests and the screenshot mode: no network.
class FakeGeocodingRepository implements GeocodingRepository {
  FakeGeocodingRepository({this.results, this.failure});

  /// What `search` returns; defaults to one fixed match.
  List<GeocodingResult>? results;

  /// Thrown by the next call (and every one after, until cleared).
  Object? failure;

  final List<String> searches = [];
  final List<(double, double)> reverses = [];

  @override
  Future<List<GeocodingResult>> search(String query) async {
    searches.add(query);
    final Object? error = failure;
    if (error != null) throw error;
    return results ??
        const [
          GeocodingResult(
            displayName: 'Fake Cafe, 1 Test Street, Testville',
            title: 'Fake Cafe',
            latitude: 50.4501,
            longitude: 30.5234,
          ),
        ];
  }

  @override
  Future<GeocodingResult?> reverse(double latitude, double longitude) async {
    reverses.add((latitude, longitude));
    final Object? error = failure;
    if (error != null) throw error;
    return GeocodingResult(
      displayName: '1 Test Street, Testville, Testland',
      title: '1 Test Street',
      latitude: latitude,
      longitude: longitude,
    );
  }
}
```

### Лістинг 24 — `NominatimGeocodingRepository` (dio)

Файл: `lib/data/repositories/nominatim_geocoding_repository.dart`

```dart
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
```

### Лістинг 25 — `GeocodingFailure`

Файл: `lib/core/errors/geocoding_failure.dart`

```dart
import '../constants/app_strings.dart';

enum GeocodingFailureType {
  /// No connection or the host cannot be reached.
  network,

  /// The server did not answer in time.
  timeout,

  /// The server answered with an error (4xx/5xx, e.g. rate limiting).
  server,
}

/// A REST (Nominatim) request failed. `DioException`s are translated into
/// this so the Cubit and UI never import `dio`.
class GeocodingFailure implements Exception {
  const GeocodingFailure(this.type, {this.statusCode});

  final GeocodingFailureType type;
  final int? statusCode;

  String get message => switch (type) {
    GeocodingFailureType.network => AppStrings.errorOffline,
    GeocodingFailureType.timeout => AppStrings.errorSearchTimeout,
    GeocodingFailureType.server => AppStrings.errorSearchServer,
  };

  @override
  String toString() => 'GeocodingFailure($type, $statusCode)';
}
```

### Лістинг 26 — `LocationPickerCubit`

Файл: `lib/features/places/bloc/location_picker_cubit.dart`

```dart
// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/geocoding_failure.dart';
import '../../../data/models/geocoding_result.dart';
import '../../../data/repositories/geocoding_repository.dart';
import '../../../data/repositories/venues_repository.dart';
import '../../../data/services/location_service.dart';

enum LocationPickerStatus {
  /// Nothing is running; the card shows the current point.
  idle,

  /// An address / venue search (submitted text) is running.
  searching,

  /// The address of the map centre is being looked up.
  resolving,

  /// The phone's position is being read.
  locating,

  /// The card shows a resolved address for the current point.
  ready,

  /// A search or lookup failed; [LocationPickerState.message] says why.
  error,
}

/// What part of the map the user sees; used to ask for venues in view.
class MapViewport {
  const MapViewport({required this.bounds, required this.zoom});

  final GeoBounds bounds;
  final double zoom;
}

class LocationPickerState extends Equatable {
  const LocationPickerState({
    required this.center,
    this.status = LocationPickerStatus.idle,
    this.title = '',
    this.address = '',
    this.results = const [],
    this.venues = const [],
    this.selected,
    this.message,
    this.recenterTick = 0,
  });

  /// The chosen point: always the centre of the map under the pin.
  final LatLng center;
  final LocationPickerStatus status;

  /// Card header (first part of the address) and the full address.
  final String title;
  final String address;

  /// Several matches of the last search, shown under the search panel.
  final List<GeocodingResult> results;

  /// Venues around the visible part of the map, drawn as markers.
  final List<GeocodingResult> venues;

  /// The venue the user tapped or picked from the results (its name and
  /// kind go back to the form); `null` once the map is moved away.
  final GeocodingResult? selected;

  final String? message;

  /// Increments when the *cubit* wants the map to jump to [center] (after a
  /// search or "my location"); a drag by the user does not change it. The
  /// screen moves the map controller when it changes, which avoids a
  /// feedback loop.
  final int recenterTick;

  bool get hasAddress => address.isNotEmpty;

  LocationPickerState copyWith({
    LatLng? center,
    LocationPickerStatus? status,
    String? title,
    String? address,
    List<GeocodingResult>? results,
    List<GeocodingResult>? venues,
    GeocodingResult? selected,
    bool clearSelected = false,
    String? message,
    bool clearMessage = false,
    bool recenter = false,
  }) {
    return LocationPickerState(
      center: center ?? this.center,
      status: status ?? this.status,
      title: title ?? this.title,
      address: address ?? this.address,
      results: results ?? this.results,
      venues: venues ?? this.venues,
      selected: clearSelected ? null : selected ?? this.selected,
      message: clearMessage ? null : message ?? this.message,
      recenterTick: recenter ? recenterTick + 1 : recenterTick,
    );
  }

  @override
  List<Object?> get props => [
    center,
    status,
    title,
    address,
    results,
    venues,
    selected,
    message,
    recenterTick,
  ];
}

/// State of the location picker: search, "my location", the point under the
/// pin, its address and the venues around it.
///
/// * Search happens **on submit** only (the public Nominatim service forbids
///   autocomplete). It looks for venues by name near the map centre *and*
///   for addresses, and lists both.
/// * When the map stops moving, the address and the venues in view are looked
///   up after a short [debounce], so a drag produces one request, not
///   hundreds. A lookup that finishes after the map moved on is discarded.
/// * A failed lookup keeps the previous address, but the coordinates still
///   follow the map, so the user can always confirm. Venues are a bonus:
///   if they cannot be loaded nothing is shown and nothing breaks.
class LocationPickerCubit extends Cubit<LocationPickerState> {
  LocationPickerCubit({
    required GeocodingRepository geocoding,
    required VenuesRepository venues,
    required LocationService location,
    required LatLng initialCenter,
    String initialAddress = '',
    this.debounce = const Duration(milliseconds: 700),
  }) : _geocoding = geocoding,
       _venues = venues,
       _location = location,
       super(
         LocationPickerState(
           center: initialCenter,
           address: initialAddress,
           title: initialAddress.split(',').first.trim(),
           status: initialAddress.isEmpty
               ? LocationPickerStatus.idle
               : LocationPickerStatus.ready,
         ),
       );

  final GeocodingRepository _geocoding;
  final VenuesRepository _venues;
  final LocationService _location;
  final Duration debounce;

  /// Venues are only drawn when zoomed in enough to see individual streets.
  static const double minVenueZoom = 15;

  Timer? _timer;

  /// Identifies the latest lookup; older answers are dropped.
  int _lookup = 0;

  /// The map is being moved: the coordinates follow, no request is made yet.
  void mapMoving(LatLng center) {
    _timer?.cancel();
    _lookup++; // whatever is in flight is already outdated
    emit(
      state.copyWith(center: center, clearSelected: true, clearMessage: true),
    );
  }

  /// The user let go of the map: look up the address (and the venues in
  /// [viewport]) after [debounce].
  void mapMoved(LatLng center, {MapViewport? viewport}) {
    _timer?.cancel();
    _lookup++;
    emit(state.copyWith(center: center, clearSelected: true));
    _timer = Timer(debounce, () {
      _resolve(center);
      if (viewport != null && viewport.zoom >= minVenueZoom) {
        _loadVenues(viewport.bounds);
      }
    });
  }

  /// Loads the venues of the first view of the map (when the picker opens,
  /// or after the map is ready) without touching the address.
  void showVenuesIn(MapViewport viewport) {
    if (viewport.zoom >= minVenueZoom) _loadVenues(viewport.bounds);
  }

  Future<void> _resolve(LatLng center) async {
    final int mine = ++_lookup;
    emit(
      state.copyWith(
        status: LocationPickerStatus.resolving,
        clearMessage: true,
      ),
    );
    try {
      final GeocodingResult? found = await _geocoding.reverse(
        center.latitude,
        center.longitude,
      );
      if (isClosed || mine != _lookup) return;
      emit(
        found == null
            ? state.copyWith(status: LocationPickerStatus.idle)
            : state.copyWith(
                status: LocationPickerStatus.ready,
                title: found.title,
                address: found.displayName,
              ),
      );
    } on GeocodingFailure catch (failure) {
      if (isClosed || mine != _lookup) return;
      // Keep the previous address; the coordinates are already current.
      emit(
        state.copyWith(
          status: LocationPickerStatus.error,
          message: failure.message,
        ),
      );
    }
  }

  /// Fetches venues for the markers. Not part of [_lookup]: it does not
  /// block or cancel the address lookup, and its failure is ignored.
  Future<void> _loadVenues(GeoBounds bounds) async {
    try {
      final List<GeocodingResult> found = await _venues.nearby(bounds);
      if (!isClosed) emit(state.copyWith(venues: found));
    } on GeocodingFailure {
      // Markers are optional.
    }
  }

  /// Runs the typed search: venues with that name near the map centre, and
  /// addresses. One match centres the map on it; several are listed.
  Future<void> search(String query) async {
    final String q = query.trim();
    if (q.isEmpty) return;
    _timer?.cancel();
    final int mine = ++_lookup;
    emit(
      state.copyWith(
        status: LocationPickerStatus.searching,
        results: const [],
        clearMessage: true,
      ),
    );
    GeocodingFailure? failure;
    Future<List<GeocodingResult>> safe(
      Future<List<GeocodingResult>> call,
    ) async {
      try {
        return await call;
      } on GeocodingFailure catch (f) {
        failure = f;
        return const [];
      }
    }

    final List<List<GeocodingResult>> both = await Future.wait([
      safe(
        _venues.searchByName(
          q,
          latitude: state.center.latitude,
          longitude: state.center.longitude,
        ),
      ),
      safe(_geocoding.search(q)),
    ]);
    if (isClosed || mine != _lookup) return;

    final List<GeocodingResult> merged = _merge(both[0], both[1]);
    if (merged.isEmpty) {
      emit(
        state.copyWith(
          status: LocationPickerStatus.error,
          message: failure?.message ?? AppStrings.searchNoResults,
        ),
      );
    } else if (merged.length == 1) {
      _select(merged.first);
    } else {
      emit(state.copyWith(status: LocationPickerStatus.idle, results: merged));
    }
  }

  /// Venues first (they are what the user usually means), then addresses,
  /// without the same spot twice.
  static List<GeocodingResult> _merge(
    List<GeocodingResult> venues,
    List<GeocodingResult> addresses,
  ) {
    final List<GeocodingResult> out = [...venues.take(6)];
    for (final GeocodingResult a in addresses) {
      final bool duplicate = out.any(
        (GeocodingResult v) =>
            (v.latitude - a.latitude).abs() < 0.0003 &&
            (v.longitude - a.longitude).abs() < 0.0003,
      );
      if (!duplicate) out.add(a);
      if (out.length >= 8) break;
    }
    return out;
  }

  /// The user picked a listed match or tapped a venue marker.
  void selectResult(GeocodingResult result) => _select(result);

  void _select(GeocodingResult result) {
    _lookup++;
    emit(
      state.copyWith(
        center: LatLng(result.latitude, result.longitude),
        status: LocationPickerStatus.ready,
        title: result.title,
        address: result.displayName,
        results: const [],
        selected: result.isVenue ? result : null,
        clearSelected: !result.isVenue,
        clearMessage: true,
        recenter: true,
      ),
    );
    // Show what else is around the chosen spot.
    _loadVenues(GeoBounds.around(result.latitude, result.longitude));
  }

  /// "My location": reads the phone's position, moves the map there, names
  /// the spot and shows the venues around it.
  Future<void> useMyLocation() async {
    if (state.status == LocationPickerStatus.locating) return;
    _timer?.cancel();
    final int mine = ++_lookup;
    emit(
      state.copyWith(
        status: LocationPickerStatus.locating,
        results: const [],
        clearMessage: true,
      ),
    );
    try {
      final ({double latitude, double longitude}) here = await _location
          .currentPosition();
      if (isClosed || mine != _lookup) return;
      final LatLng point = LatLng(here.latitude, here.longitude);
      emit(
        state.copyWith(
          center: point,
          status: LocationPickerStatus.resolving,
          clearSelected: true,
          recenter: true,
        ),
      );
      _loadVenues(GeoBounds.around(here.latitude, here.longitude));
      await _resolve(point);
    } on LocationFailure catch (failure) {
      if (isClosed || mine != _lookup) return;
      emit(
        state.copyWith(
          status: LocationPickerStatus.error,
          message: failure.message,
        ),
      );
    }
  }

  /// Moves the map to a place whose address is known but whose coordinates
  /// are not (an old record). Quiet: finding nothing or failing is fine,
  /// the picker just stays on its default centre.
  Future<void> centerOnAddress(String address) async {
    final int mine = ++_lookup;
    try {
      final List<GeocodingResult> found = await _geocoding.search(address);
      if (isClosed || mine != _lookup || found.isEmpty) return;
      final GeocodingResult first = found.first;
      emit(
        state.copyWith(
          center: LatLng(first.latitude, first.longitude),
          recenter: true,
        ),
      );
    } on GeocodingFailure {
      // Ignored on purpose (see above).
    }
  }

  /// What the form receives. The address falls back to the coordinates when
  /// no address could be resolved (e.g. offline). A chosen venue also hands
  /// over its name and kind.
  PickedLocation get picked {
    final GeocodingResult? venue = state.selected;
    return PickedLocation(
      address: state.hasAddress
          ? state.address
          : '${state.center.latitude.toStringAsFixed(5)}, '
                '${state.center.longitude.toStringAsFixed(5)}',
      latitude: state.center.latitude,
      longitude: state.center.longitude,
      name: venue?.title,
      category: venue?.category,
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
```

## 7. Вибір фото

### Лістинг 27 — `PhotoPickerService`, правила й обробка помилок

Файл: `lib/data/services/photo_picker_service.dart`

```dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_strings.dart';
import '../models/place_photo.dart';

/// Why choosing a photo failed. A user *cancelling* is not a failure: the
/// picker methods return an empty result for that.
enum PhotoPickFailureType {
  photosDenied,
  cameraDenied,
  noCamera,
  tooLarge,
  unsupportedType,
  readFailed,
}

class PhotoPickFailure implements Exception {
  const PhotoPickFailure(this.type);

  final PhotoPickFailureType type;

  String get message => switch (type) {
    PhotoPickFailureType.photosDenied => AppStrings.photoErrorPermission,
    PhotoPickFailureType.cameraDenied => AppStrings.photoErrorCameraPermission,
    PhotoPickFailureType.noCamera => AppStrings.photoErrorNoCamera,
    PhotoPickFailureType.tooLarge => AppStrings.photoErrorTooLarge,
    PhotoPickFailureType.unsupportedType => AppStrings.photoErrorUnsupported,
    PhotoPickFailureType.readFailed => AppStrings.photoErrorRead,
  };

  @override
  String toString() => 'PhotoPickFailure($type)';
}

/// Limits for a photo that will be uploaded (also enforced by the bucket).
abstract final class PhotoRules {
  static const int maxPhotosPerPlace = 5;
  static const int maxBytes = 5 * 1024 * 1024;

  /// Quality and size the picker compresses to (requirement NFR4): a phone
  /// photo of several MB becomes a few hundred KB before upload.
  static const int imageQuality = 80;
  static const double maxDimension = 1600;

  static const Map<String, String> contentTypeByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  /// The MIME type for [path], or throws [PhotoPickFailure] when the file is
  /// not a supported image or is larger than [maxBytes].
  static String validate(String path, int sizeBytes) {
    final int dot = path.lastIndexOf('.');
    final String extension = dot == -1
        ? ''
        : path.substring(dot + 1).toLowerCase();
    final String? contentType = contentTypeByExtension[extension];
    if (contentType == null) {
      throw const PhotoPickFailure(PhotoPickFailureType.unsupportedType);
    }
    if (sizeBytes > maxBytes) {
      throw const PhotoPickFailure(PhotoPickFailureType.tooLarge);
    }
    return contentType;
  }
}

/// Lets the user pick photos. An interface so the form can be tested with a
/// fake instead of the real `image_picker` plugin (which needs a device).
abstract interface class PhotoPickerService {
  /// Up to [limit] photos from the library; an empty list if cancelled.
  Future<List<PlacePhoto>> pickFromLibrary({required int limit});

  /// One new camera photo; `null` if cancelled.
  Future<PlacePhoto?> takePhoto();
}

/// [PhotoPickerService] on `image_picker`. The photos are compressed by the
/// picker itself ([PhotoRules.imageQuality], [PhotoRules.maxDimension]) and
/// returned as [PhotoKind.local] — still on the device, not yet uploaded.
class ImagePickerPhotoService implements PhotoPickerService {
  ImagePickerPhotoService([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<PlacePhoto>> pickFromLibrary({required int limit}) async {
    if (limit < 1) return const [];
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: PhotoRules.imageQuality,
        maxWidth: PhotoRules.maxDimension,
        maxHeight: PhotoRules.maxDimension,
        limit: limit,
        // The system picker needs no permission; asking for full metadata
        // would make iOS prompt for library access for nothing.
        requestFullMetadata: false,
      );
      return [for (final XFile f in files.take(limit)) await _toPhoto(f)];
    } on PlatformException catch (e) {
      throw _fromPlatform(e);
    }
  }

  @override
  Future<PlacePhoto?> takePhoto() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: PhotoRules.imageQuality,
        maxWidth: PhotoRules.maxDimension,
        maxHeight: PhotoRules.maxDimension,
      );
      return file == null ? null : await _toPhoto(file);
    } on PlatformException catch (e) {
      throw _fromPlatform(e);
    }
  }

  Future<PlacePhoto> _toPhoto(XFile file) async {
    final int size;
    try {
      size = await File(file.path).length();
    } on FileSystemException {
      throw const PhotoPickFailure(PhotoPickFailureType.readFailed);
    }
    final String contentType = PhotoRules.validate(file.path, size);
    return PlacePhoto.local(
      file.path,
      fileSizeBytes: size,
      contentType: contentType,
    );
  }

  /// Plugin error codes (from the iOS/Android implementations).
  PhotoPickFailure _fromPlatform(PlatformException e) => switch (e.code) {
    'photo_access_denied' => const PhotoPickFailure(
      PhotoPickFailureType.photosDenied,
    ),
    'camera_access_denied' => const PhotoPickFailure(
      PhotoPickFailureType.cameraDenied,
    ),
    'no_available_camera' => const PhotoPickFailure(
      PhotoPickFailureType.noCamera,
    ),
    _ => const PhotoPickFailure(PhotoPickFailureType.readFailed),
  };
}

/// A scripted picker for tests and screenshot mode.
class FakePhotoPickerService implements PhotoPickerService {
  FakePhotoPickerService({this.library = const [], this.camera, this.failure});

  /// What "Choose from Library" returns (trimmed to the requested limit).
  List<PlacePhoto> library;

  /// What "Take Photo" returns; `null` simulates cancelling.
  PlacePhoto? camera;

  /// Thrown by the next call, then cleared.
  PhotoPickFailure? failure;

  int libraryCalls = 0;
  int cameraCalls = 0;
  int lastLimit = 0;

  void _maybeFail() {
    final PhotoPickFailure? f = failure;
    if (f != null) {
      failure = null;
      throw f;
    }
  }

  @override
  Future<List<PlacePhoto>> pickFromLibrary({required int limit}) async {
    libraryCalls++;
    lastLimit = limit;
    _maybeFail();
    return library.take(limit).toList();
  }

  @override
  Future<PlacePhoto?> takePhoto() async {
    cameraCalls++;
    _maybeFail();
    return camera;
  }
}
```

### Лістинг 28 — `CupertinoActionSheet` вибору джерела

Файл: `lib/features/places/screens/add_place_pickers.dart` (фрагмент)



```dart
/// Where a new photo comes from.
enum PhotoSource { camera, library }

/// iOS action sheet "Take Photo / Choose from Library / Cancel"; resolves to
/// the choice or `null` when cancelled.
Future<PhotoSource?> showPhotoSourceSheet(BuildContext context) {
  return showCupertinoModalPopup<PhotoSource>(
    context: context,
    builder: (BuildContext context) => CupertinoActionSheet(
      title: const Text(AppStrings.photoSourceTitle),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(PhotoSource.camera),
          child: const Text(AppStrings.takePhoto),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(PhotoSource.library),
          child: const Text(AppStrings.chooseFromLibrary),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(AppStrings.cancel),
      ),
    ),
  );
}
```

### Лістинг 29 — Додавання фото у формі

Файл: `lib/features/places/screens/place_form_screen.dart` (фрагмент)



```dart
  /// Opens the source sheet, then adds what the user picked. Cancelling
  /// does nothing; a denied permission or a bad file shows a plain message.
  Future<void> _addPhoto() async {
    final int free = _maxPhotos - _photos.length;
    if (free < 1) return;
    final PhotoSource? source = await showPhotoSourceSheet(context);
    if (source == null || !mounted) return;
    final PhotoPickerService picker = context.read<PhotoPickerService>();
    try {
      final List<PlacePhoto> picked = switch (source) {
        PhotoSource.library => await picker.pickFromLibrary(limit: free),
        PhotoSource.camera => [?await picker.takePhoto()],
      };
      if (!mounted || picked.isEmpty) return;
      // The preview is the local file itself: shown at once, no network.
      setState(
        () => _photos = [..._photos, ...picked].take(_maxPhotos).toList(),
      );
    } on PhotoPickFailure catch (failure) {
      if (!mounted) return;
      await AppConfirmDialog.show(
        context,
        title: AppStrings.photoErrorTitle,
        message: failure.message,
        confirmLabel: AppStrings.ok,
        cancelLabel: null,
      );
    }
  }
```

### Лістинг 30 — `PlaceImageView`: один віджет для всіх походжень фото

Файл: `lib/core/widgets/place_image_view.dart`

```dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';

import '../../data/models/place_photo.dart';
import '../theme/app_colors.dart';

/// The one widget that shows a [PlacePhoto], whatever its origin:
/// bundled asset, a file on this device, or an uploaded photo.
///
/// Having a single place that knows the three cases keeps cards, the details
/// hero, the form and the gallery identical, and a new origin only needs
/// handling here. Network photos get a placeholder while loading and an
/// error tile if the URL cannot be fetched (offline, deleted file).
class PlaceImageView extends StatelessWidget {
  const PlaceImageView({
    super.key,
    required this.photo,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final PlacePhoto photo;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Tests replace the network branch: `cached_network_image` needs a
  /// database and a real HTTP client, which unit tests must not touch.
  @visibleForTesting
  static Widget Function(String url)? debugRemoteBuilder;

  @override
  Widget build(BuildContext context) {
    switch (photo.kind) {
      case PhotoKind.asset:
        return Image.asset(
          photo.location,
          width: width,
          height: height,
          fit: fit,
        );
      case PhotoKind.local:
        return Image.file(
          File(photo.location),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => const _PhotoFallback(),
        );
      case PhotoKind.remote:
        final Widget Function(String)? override = debugRemoteBuilder;
        if (override != null) return override(photo.location);
        return CachedNetworkImage(
          imageUrl: photo.location,
          width: width,
          height: height,
          fit: fit,
          placeholder: (_, _) => const _PhotoPlaceholder(),
          errorWidget: (_, _, _) => const _PhotoFallback(),
        );
    }
  }
}

/// Grey tile with a spinner while a network photo loads.
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceContainer,
      child: Center(child: CupertinoActivityIndicator()),
    );
  }
}

/// Grey tile with a picture icon when the photo cannot be shown.
class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceContainer,
      child: Center(
        child: Icon(CupertinoIcons.photo, color: AppColors.textTertiary),
      ),
    );
  }
}
```

## 8. Мапа

### Лістинг 31 — `LocationPickerScreen`

Файл: `lib/features/places/screens/location_picker_screen.dart`

```dart
import 'dart:ui';

import 'package:flutter/cupertino.dart'
    show CupertinoActivityIndicator, CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/map_defaults.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/coordinates_formatter.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/osm_tile_layer.dart';
import '../../../core/widgets/pressable_opacity.dart';
import '../../../data/models/geocoding_result.dart';
import '../../../data/repositories/geocoding_repository.dart';
import '../../../data/repositories/venues_repository.dart';
import '../../../data/services/location_service.dart';
import '../bloc/location_picker_cubit.dart';
import '../widgets/venue_marker.dart';
import '../../../core/widgets/app_text_link.dart';
import '../../../core/widgets/primary_button.dart';

/// Location picker (FR11) shown as a full-screen modal.
///
/// A real OpenStreetMap map (`flutter_map`) with a **fixed pin in the
/// centre**: the chosen point is whatever is under the pin, so the user
/// pans and zooms the map instead of moving a marker. The address of that
/// point is looked up by `LocationPickerCubit` (reverse geocoding, after the
/// map stops moving); typing an address and submitting searches for it.
/// "Confirm" pops a [PickedLocation]; "Cancel" pops `null`.
class LocationPickerScreen extends StatelessWidget {
  const LocationPickerScreen({super.key, this.initial});

  /// The place's current location when editing; `null` for a new place.
  final LocationPickerArgs? initial;

  @override
  Widget build(BuildContext context) {
    final LocationPickerArgs? start = initial;
    return BlocProvider<LocationPickerCubit>(
      create: (BuildContext context) => LocationPickerCubit(
        geocoding: context.read<GeocodingRepository>(),
        venues: context.read<VenuesRepository>(),
        location: context.read<LocationService>(),
        initialCenter: start != null && start.hasPoint
            ? LatLng(start.latitude!, start.longitude!)
            : MapDefaults.center,
        initialAddress: start?.address ?? '',
      ),
      child: _LocationPickerView(initial: start),
    );
  }
}

class _LocationPickerView extends StatefulWidget {
  const _LocationPickerView({required this.initial});

  final LocationPickerArgs? initial;

  @override
  State<_LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<_LocationPickerView> {
  final MapController _map = MapController();
  late final TextEditingController _queryController = TextEditingController(
    text: widget.initial?.address ?? '',
  );

  /// The map is being dragged: the pin lifts, like a real one.
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    final LocationPickerArgs? start = widget.initial;
    // An old record has an address but no point: try to find it on the map.
    final LocationPickerCubit cubit = context.read<LocationPickerCubit>();
    if (start != null && !start.hasPoint && start.address.isNotEmpty) {
      cubit.centerOnAddress(start.address);
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _map.dispose();
    super.dispose();
  }

  /// The part of the map the user sees now, for the venue markers.
  MapViewport _viewport(MapCamera camera) {
    final LatLngBounds b = camera.visibleBounds;
    return MapViewport(
      bounds: GeoBounds(
        south: b.south,
        west: b.west,
        north: b.north,
        east: b.east,
      ),
      zoom: camera.zoom,
    );
  }

  /// First frame of the map: name the starting point (a fresh picker only —
  /// an edited place keeps its saved address) and show venues around it.
  void _onMapReady() {
    final LocationPickerCubit cubit = context.read<LocationPickerCubit>();
    final MapViewport view = _viewport(_map.camera);
    final LocationPickerArgs? start = widget.initial;
    if (start == null || start.address.isEmpty) {
      cubit.mapMoved(cubit.state.center, viewport: view);
    } else {
      cubit.showVenuesIn(view);
    }
  }

  void _onMapEvent(MapEvent event) {
    // Moves made by the cubit itself (after a search) are not the user's.
    if (event.source == MapEventSource.mapController) return;
    final LocationPickerCubit cubit = context.read<LocationPickerCubit>();
    if (event is MapEventMoveStart) {
      setState(() => _dragging = true);
    } else if (event is MapEventMoveEnd) {
      setState(() => _dragging = false);
      cubit.mapMoved(event.camera.center, viewport: _viewport(event.camera));
    } else if (event is MapEventMove) {
      cubit.mapMoving(event.camera.center);
    }
  }

  void _search() {
    FocusScope.of(context).unfocus();
    context.read<LocationPickerCubit>().search(_queryController.text);
  }

  void _clear() {
    _queryController.clear();
    setState(() {});
  }

  void _confirm() {
    Navigator.of(context).pop(context.read<LocationPickerCubit>().picked);
  }

  @override
  Widget build(BuildContext context) {
    final LocationPickerCubit cubit = context.read<LocationPickerCubit>();
    return Scaffold(
      body: BlocListener<LocationPickerCubit, LocationPickerState>(
        listenWhen: (before, now) => before.recenterTick != now.recenterTick,
        listener: (BuildContext context, LocationPickerState state) {
          _map.move(state.center, MapDefaults.focusZoom);
          _queryController.text = state.address;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: cubit.state.center,
                initialZoom: MapDefaults.zoom,
                backgroundColor: OsmTileLayer.background,
                onMapEvent: _onMapEvent,
                onMapReady: _onMapReady,
              ),
              children: [
                const OsmTileLayer(),
                // Venues around the view, as the app's own markers (OSM tiles
                // carry no cafe icons). Tapping one chooses it.
                BlocBuilder<LocationPickerCubit, LocationPickerState>(
                  buildWhen: (a, b) =>
                      a.venues != b.venues || a.selected != b.selected,
                  builder: (BuildContext context, LocationPickerState state) =>
                      MarkerLayer(
                        markers: [
                          for (final GeocodingResult v in state.venues)
                            Marker(
                              point: LatLng(v.latitude, v.longitude),
                              width: VenueMarker.size,
                              height: VenueMarker.size,
                              child: VenueMarker(
                                category: v.category!,
                                label: v.title,
                                selected: state.selected == v,
                                onTap: () => cubit.selectResult(v),
                              ),
                            ),
                        ],
                      ),
                ),
              ],
            ),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.scrim5,
                      AppColors.transparent,
                      AppColors.scrim10,
                    ],
                  ),
                ),
              ),
            ),
            // The pin's tip is the chosen point (the centre of the map).
            IgnorePointer(
              child: Align(
                alignment: const Alignment(0, -0.06),
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 150),
                  offset: Offset(0, _dragging ? -0.12 : 0),
                  child: const _DropPin(),
                ),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.only(bottom: AppSpacing.l),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    _SearchBar(
                      controller: _queryController,
                      onSubmitted: _search,
                      onClear: _clear,
                    ),
                    const _SearchResults(),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _AttributionChip(),
                      ),
                    ),
                    _LocationCard(onConfirm: _confirm),
                  ],
                ),
              ),
            ),
            // Under the search panel, out of the column's height so it never
            // adds to it (small screens, open keyboard). Hidden while a list of
            // results is shown, which would sit under it.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 84, right: AppSpacing.l),
                child: Align(
                  alignment: Alignment.topRight,
                  child: BlocBuilder<LocationPickerCubit, LocationPickerState>(
                    buildWhen: (a, b) => a.results.isEmpty != b.results.isEmpty,
                    builder: (BuildContext context, LocationPickerState s) =>
                        s.results.isEmpty
                        ? const _MyLocationButton()
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round button that moves the map to where the phone is.
class _MyLocationButton extends StatelessWidget {
  const _MyLocationButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationPickerCubit, LocationPickerState>(
      buildWhen: (a, b) =>
          (a.status == LocationPickerStatus.locating) !=
          (b.status == LocationPickerStatus.locating),
      builder: (BuildContext context, LocationPickerState state) {
        final bool busy = state.status == LocationPickerStatus.locating;
        return Semantics(
          button: true,
          label: AppStrings.myLocationLabel,
          child: PressableOpacity(
            onTap: busy
                ? null
                : () => context.read<LocationPickerCubit>().useMyLocation(),
            child: Container(
              width: AppSpacing.minTapTarget,
              height: AppSpacing.minTapTarget,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.glass95,
                shape: BoxShape.circle,
                boxShadow: AppShadows.floating,
              ),
              child: busy
                  ? const CupertinoActivityIndicator()
                  : const Icon(
                      CupertinoIcons.location_fill,
                      size: 20,
                      color: AppColors.primary,
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// The map credit on a small frosted chip, always visible above the card.
class _AttributionChip extends StatelessWidget {
  const _AttributionChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.glass90,
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      child: const OsmAttribution(),
    );
  }
}

/// Several matches of a search, in the same frosted style as the panel.
class _SearchResults extends StatelessWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationPickerCubit, LocationPickerState>(
      buildWhen: (a, b) => a.results != b.results,
      builder: (BuildContext context, LocationPickerState state) {
        if (state.results.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s),
          child: _Glass(
            color: AppColors.glass95,
            radius: AppRadii.lg,
            blur: 12,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                for (final GeocodingResult r in state.results)
                  PressableOpacity(
                    onTap: () =>
                        context.read<LocationPickerCubit>().selectResult(r),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                        vertical: AppSpacing.sm,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          spacing: AppSpacing.sm,
                          children: [
                            if (r.category != null)
                              Icon(
                                venueIcon(r.category!),
                                size: 18,
                                color: AppColors.primary,
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.title,
                                    style: AppTextStyles.subheadline,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    r.displayName,
                                    style: AppTextStyles.footnote.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      color: AppColors.glass85,
      radius: AppRadii.lg,
      blur: 12,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.ml,
        vertical: 10,
      ),
      child: Row(
        spacing: AppSpacing.m,
        children: [
          AppTextLink(
            label: AppStrings.cancel,
            style: AppTextStyles.body,
            horizontalPadding: AppSpacing.xs,
            onTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: AppColors.mapSearchBackground,
                borderRadius: AppRadii.mdAll,
              ),
              child: Row(
                spacing: AppSpacing.sm,
                children: [
                  GestureDetector(
                    onTap: onSubmitted,
                    behavior: HitTestBehavior.opaque,
                    child: const AppSvgIcon(AppAssets.iconSearch),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: AppTextStyles.mapSearch,
                      textInputAction: TextInputAction.search,
                      // Search runs on submit only (no autocomplete: the
                      // public Nominatim service forbids it).
                      onSubmitted: (_) => onSubmitted(),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration.collapsed(
                        hintText: AppStrings.location,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      width: 18.34,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: AppRadii.pillAll,
                      ),
                      child: const AppSvgIcon(AppAssets.iconCloseSmall),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        boxShadow: AppShadows.floating,
      ),
      child: _Glass(
        color: AppColors.glass95,
        radius: 24,
        blur: 20,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.l,
          children: [
            const Center(
              child: SizedBox(
                width: 36,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: AppRadii.pillAll,
                  ),
                ),
              ),
            ),
            const _PickedPlaceInfo(),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: PrimaryButton(
                label: AppStrings.confirmLocation,
                icon: const AppSvgIcon(AppAssets.iconCheckCircle),
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickedPlaceInfo extends StatelessWidget {
  const _PickedPlaceInfo();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationPickerCubit, LocationPickerState>(
      builder: (BuildContext context, LocationPickerState state) {
        final bool busy =
            state.status == LocationPickerStatus.resolving ||
            state.status == LocationPickerStatus.searching;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.ml,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: AppRadii.lgAll,
                ),
                child: busy
                    ? const CupertinoActivityIndicator()
                    : const AppSvgIcon(AppAssets.iconLocationArrow),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xxs,
                children: [
                  Text(
                    state.hasAddress
                        ? state.title
                        : AppStrings.pickedPlaceTitle,
                    style: AppTextStyles.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    state.hasAddress ? state.address : AppStrings.moveMapHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subheadline.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Row(
                      spacing: AppSpacing.xs,
                      children: [
                        const AppSvgIcon(AppAssets.iconCompass),
                        Flexible(
                          child: Text(
                            formatCoordinates(
                              state.center.latitude,
                              state.center.longitude,
                            ),
                            style: AppTextStyles.footnote.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.status == LocationPickerStatus.error)
                    Text(
                      state.message ?? AppStrings.errorUnknown,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.destructive,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Red map pin with its ground shadow and anchor dot.
class _DropPin extends StatelessWidget {
  const _DropPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppSvgIcon(AppAssets.iconMapPin),
        const SizedBox(height: AppSpacing.xxs),
        SizedBox(
          width: 32,
          height: 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 0.75, sigmaY: 0.75),
                child: const SizedBox(
                  width: 20,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.scrim30,
                      borderRadius: AppRadii.pillAll,
                    ),
                  ),
                ),
              ),
              const SizedBox.square(
                dimension: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.destructive,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Frosted panel: clip + backdrop blur + translucent fill.
class _Glass extends StatelessWidget {
  const _Glass({
    required this.color,
    required this.radius,
    required this.blur,
    required this.padding,
    required this.child,
  });

  final Color color;
  final double radius;
  final double blur;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(color: color, padding: padding, child: child),
      ),
    );
  }
}
```

### Лістинг 32 — Міні-мапа на Place Details

Файл: `lib/features/places/widgets/details_sections.dart` (фрагмент)



```dart
/// "Location & Coordinates": a small real map (OpenStreetMap) with a pin on
/// the place and the street label.
///
/// The map cannot be panned or zoomed (it is a preview); tapping it, or
/// "Open in Maps", hands the point to the phone's Maps app. A place saved
/// without coordinates (an old record) shows a calm "Location is not set"
/// tile instead — nothing breaks.
class LocationSection extends StatelessWidget {
  const LocationSection({
    super.key,
    required this.label,
    required this.onOpenMaps,
    this.latitude,
    this.longitude,
  });

  final String label;
  final double? latitude;
  final double? longitude;

  /// Called by the link and by a tap on the map; only when [hasPoint].
  final VoidCallback onOpenMaps;

  bool get hasPoint => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                AppStrings.locationTitle,
                style: AppTextStyles.footnoteSemibold,
              ),
            ),
            if (hasPoint)
              PressableOpacity(
                onTap: onOpenMaps,
                child: Text(
                  AppStrings.openInMaps,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        Container(
          height: 128,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            borderRadius: AppRadii.mdAll,
            boxShadow: AppShadows.group,
          ),
          child: hasPoint ? _buildMap() : const _NoLocation(),
        ),
      ],
    );
  }

  Widget _buildMap() {
    final LatLng point = LatLng(latitude!, longitude!);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpenMaps,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A still preview: `InteractiveFlag.none` plus `IgnorePointer`, so
          // the map's own gesture handling cannot swallow the tap that opens
          // the Maps app.
          IgnorePointer(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: MapDefaults.previewZoom,
                backgroundColor: OsmTileLayer.background,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                const OsmTileLayer(),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 32,
                      height: 32,
                      child: const _MapMarker(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: const BoxDecoration(
                color: AppColors.glass90,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              child: Text(label, style: AppTextStyles.tabLabel),
            ),
          ),
          const Positioned(
            right: AppSpacing.xs,
            bottom: AppSpacing.xxs,
            child: OsmAttribution(),
          ),
        ],
      ),
    );
  }
}

/// Shown when the place has no coordinates.
class _NoLocation extends StatelessWidget {
  const _NoLocation();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceContainerLow,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: [
            AppSvgIcon(AppAssets.iconPin),
            Text(AppStrings.locationNotSet, style: AppTextStyles.footnote),
          ],
        ),
      ),
    );
  }
}
```

### Лістинг 33 — `OsmTileLayer` і атрибуція

Файл: `lib/core/widgets/osm_tile_layer.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// OpenStreetMap raster tiles for `flutter_map`.
///
/// The tile server's policy requires an identifying `User-Agent` (taken
/// from [packageName], the app id) and visible credit — see
/// [OsmAttribution], which every map screen must show.
///
/// Tiles are only fetched when [useNetworkTiles] is on. `main.dart` turns it
/// on for a normal run; tests and the screenshot mode leave it off, so they
/// stay offline and deterministic: the map is then just a plain background.
class OsmTileLayer extends StatelessWidget {
  const OsmTileLayer({super.key});

  /// Off by default so no test can reach the network by accident.
  static bool useNetworkTiles = false;

  static const String packageName = 'ua.lpnu.pz33.placesCatalog';
  static const String urlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Plain colour behind (and instead of) the tiles.
  static const Color background = AppColors.surfaceContainer;

  @override
  Widget build(BuildContext context) {
    if (!useNetworkTiles) return const SizedBox.shrink();
    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: packageName,
    );
  }
}

/// "© OpenStreetMap contributors" — the credit the data licence (ODbL) and
/// the tile usage policy ask for. Small, but always visible on a map.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  static const String text = '© OpenStreetMap contributors';

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.tabLabel.copyWith(color: AppColors.textSecondary),
    );
  }
}
```

### Лістинг 34 — `MapLauncher` (url_launcher)

Файл: `lib/data/services/map_launcher.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a point in the phone's own Maps app.
abstract interface class MapLauncher {
  /// Returns whether a maps app was opened.
  Future<bool> openLocation({
    required double latitude,
    required double longitude,
    String? label,
  });
}

/// [MapLauncher] on `url_launcher`: Apple Maps on iOS, a `geo:` link on
/// Android (the user's default maps app), a web link elsewhere.
class UrlLauncherMapLauncher implements MapLauncher {
  const UrlLauncherMapLauncher();

  /// Builds the link for the current platform (a public method so it can be
  /// tested without launching anything).
  static Uri uriFor({
    required double latitude,
    required double longitude,
    String? label,
    TargetPlatform? platform,
  }) {
    final String point = '$latitude,$longitude';
    switch (platform ?? defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return Uri.https('maps.apple.com', '/', {
          'll': point,
          if (label != null && label.isNotEmpty) 'q': label,
        });
      case TargetPlatform.android:
        return Uri(
          scheme: 'geo',
          path: point,
          queryParameters: {'q': '$point(${label ?? ''})'},
        );
      default:
        return Uri.https('www.openstreetmap.org', '/', {
          'mlat': '$latitude',
          'mlon': '$longitude',
          'zoom': '17',
        });
    }
  }

  @override
  Future<bool> openLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    try {
      return await launchUrl(
        uriFor(latitude: latitude, longitude: longitude, label: label),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}

/// Records the request; opens nothing. For tests and the screenshot mode.
class FakeMapLauncher implements MapLauncher {
  FakeMapLauncher({this.succeeds = true});

  final bool succeeds;
  final List<(double, double, String?)> opened = [];

  @override
  Future<bool> openLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    opened.add((latitude, longitude, label));
    return succeeds;
  }
}
```

## 9. Підключення в `main.dart` та `UserScope`

### Лістинг 35 — Повний `main.dart`

Файл: `lib/main.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import 'app/app.dart';
import 'core/widgets/osm_tile_layer.dart';
import 'app/dev_launch_options.dart';
import 'data/repositories/auth_repository.dart';
import 'features/session/bloc/auth_bloc.dart';
import 'data/repositories/fake_auth_repository.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/firestore/firestore_places_document_store.dart';
import 'data/repositories/firestore_places_repository.dart';
import 'data/repositories/firestore_user_profile_repository.dart';
import 'data/repositories/fake_media_repository.dart';
import 'data/repositories/geocoding_repository.dart';
import 'data/repositories/in_memory_places_repository.dart';
import 'data/repositories/nominatim_geocoding_repository.dart';
import 'data/repositories/overpass_venues_repository.dart';
import 'data/repositories/venues_repository.dart';
import 'data/repositories/media_repository.dart';
import 'data/repositories/supabase_media_repository.dart';
import 'data/repositories/user_profile_repository.dart';
import 'data/repositories/in_memory_settings_repository.dart';
import 'data/repositories/local_places_repository.dart';
import 'data/repositories/places_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/shared_prefs_settings_repository.dart';
import 'data/services/analytics_service.dart';
import 'data/services/crash_reporter.dart';
import 'data/services/location_service.dart';
import 'data/services/map_launcher.dart';
import 'data/services/photo_picker_service.dart';
import 'data/services/supabase_config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase must be ready before Auth / Analytics / Crashlytics are used.
  //    The options are generated by `flutterfire configure`.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Crashlytics catches everything that is not handled in code:
  //    errors inside the Flutter framework (build/layout/paint) …
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  //    … and asynchronous errors outside of it (futures, platform channels).
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Portrait only, dark status-bar icons on the light background.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  final CrashReporter crashReporter = FirebaseCrashReporter(
    FirebaseCrashlytics.instance,
  );
  final AuthRepository auth = DevLaunchOptions.useFakeAuth
      ? _fakeAuth()
      : FirebaseAuthRepository(crashReporter: crashReporter);

  // Screenshot mode must not touch the disk: memory repositories, with a
  // short delay so the loading state is visible.
  final bool fake = DevLaunchOptions.useFakeAuth;
  // Offline cache for Firestore (on by default on mobile; explicit here
  // because the app's reliability requirement NFR5 depends on it).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  final PlacesRepository places = fake
      ? InMemoryPlacesRepository(
          delay: const Duration(milliseconds: DevLaunchOptions.fakeLoadDelayMs),
          failLoad: DevLaunchOptions.fakeLoadFail,
        )
      : DevLaunchOptions.useLocalPlaces
      ? LocalPlacesRepository(
          directory: getApplicationDocumentsDirectory,
          crashReporter: crashReporter,
        )
      : FirestorePlacesRepository(
          store: FirestorePlacesDocumentStore(FirebaseFirestore.instance),
          crashReporter: crashReporter,
        );
  final MediaRepository media = fake
      ? FakeMediaRepository()
      : SupabaseConfig.isConfigured
      ? SupabaseMediaRepository(
          client: SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey),
          crashReporter: crashReporter,
          bucket: SupabaseConfig.bucket,
        )
      : const NotConfiguredMediaRepository();
  // Map tiles come from the network only in a normal run (never in
  // screenshot mode or tests).
  OsmTileLayer.useNetworkTiles = !fake;
  final GeocodingRepository geocoding = fake
      ? FakeGeocodingRepository()
      : NominatimGeocodingRepository(
          languageCode: PlatformDispatcher.instance.locale.languageCode,
        );
  final VenuesRepository venues = fake
      ? FakeVenuesRepository()
      : OverpassVenuesRepository();
  final LocationService location = fake
      ? FakeLocationService()
      : const GeolocatorLocationService();
  final MapLauncher mapLauncher = fake
      ? FakeMapLauncher()
      : const UrlLauncherMapLauncher();
  final UserProfileRepository profiles = fake || DevLaunchOptions.useLocalPlaces
      ? const NoopUserProfileRepository()
      : FirestoreUserProfileRepository(
          firestore: FirebaseFirestore.instance,
          crashReporter: crashReporter,
        );
  final SettingsRepository settings = fake
      ? InMemorySettingsRepository()
      : SharedPrefsSettingsRepository(await SharedPreferences.getInstance());

  // Dependency injection: every service is provided once at the root and
  // read with `context.read<T>()`; tests swap them for fakes.
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: auth),
        RepositoryProvider<PlacesRepository>.value(value: places),
        RepositoryProvider<SettingsRepository>.value(value: settings),
        RepositoryProvider<UserProfileRepository>.value(value: profiles),
        RepositoryProvider<MediaRepository>.value(value: media),
        RepositoryProvider<GeocodingRepository>.value(value: geocoding),
        RepositoryProvider<VenuesRepository>.value(value: venues),
        RepositoryProvider<LocationService>.value(value: location),
        RepositoryProvider<MapLauncher>.value(value: mapLauncher),
        RepositoryProvider<PhotoPickerService>.value(
          value: ImagePickerPhotoService(),
        ),
        RepositoryProvider<AnalyticsService>.value(
          value: FirebaseAnalyticsService(FirebaseAnalytics.instance),
        ),
        RepositoryProvider<CrashReporter>.value(value: crashReporter),
      ],
      // The session bloc lives for the whole app run.
      child: BlocProvider<AuthBloc>(
        create: (BuildContext context) =>
            AuthBloc(context.read<AuthRepository>())..add(const AuthStarted()),
        child: const PlacesCatalogApp(),
      ),
    ),
  );
}

/// Screenshot mode (debug only): screens without network or a real account.
AuthRepository _fakeAuth() {
  assert(kDebugMode, 'FAKE_AUTH is meant for debug screenshots only.');
  return DevLaunchOptions.fakeAuth == 'signed_in'
      ? FakeAuthRepository.signedIn()
      : FakeAuthRepository();
}
```

### Лістинг 36 — `UserScope`: блоки користувача

Файл: `lib/app/user_scope.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/media_repository.dart';
import '../data/repositories/places_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/user_profile_repository.dart';
import '../data/services/analytics_service.dart';
import '../data/services/crash_reporter.dart';
import '../features/home/bloc/catalog_view_cubit.dart';
import '../features/places/bloc/create_place_bloc.dart';
import '../features/places/bloc/places_bloc.dart';
import '../features/places/bloc/update_place_bloc.dart';
import '../features/profile/bloc/profile_bloc.dart';
import '../features/session/bloc/auth_bloc.dart';

/// Creates the *per-user* blocs (`PlacesBloc`, `CreatePlaceBloc`,
/// `UpdatePlaceBloc`, `CatalogViewCubit`, `ProfileBloc`) while somebody is signed in.
///
/// It sits in `MaterialApp.builder`, i.e. **above the Navigator**. That is
/// the key point: pushed routes (Details, forms) are not descendants of
/// the `AuthGate` route, so blocs provided there would be invisible to them.
///
/// `ValueKey(uid)` makes Flutter discard both blocs when the account
/// changes, so a new user starts with a fresh state and their own files.
class UserScope extends StatelessWidget {
  const UserScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (AuthState a, AuthState b) => _uid(a) != _uid(b),
      builder: (BuildContext context, AuthState state) {
        final String? uid = _uid(state);
        if (uid == null) return child;
        return MultiBlocProvider(
          key: ValueKey<String>(uid),
          providers: [
            BlocProvider<PlacesBloc>(
              create: (BuildContext context) => PlacesBloc(
                uid: uid,
                repository: context.read<PlacesRepository>(),
                analytics: context.read<AnalyticsService>(),
                media: context.read<MediaRepository>(),
                crashReporter: context.read<CrashReporter>(),
              )..add(const PlacesLoadRequested()),
            ),
            // Saving a place is split in two blocs, as in the course
            // material: one creates, one updates.
            BlocProvider<CreatePlaceBloc>(
              create: (BuildContext context) => CreatePlaceBloc(
                uid: uid,
                repository: context.read<PlacesRepository>(),
                media: context.read<MediaRepository>(),
                crashReporter: context.read<CrashReporter>(),
              ),
            ),
            BlocProvider<UpdatePlaceBloc>(
              create: (BuildContext context) => UpdatePlaceBloc(
                uid: uid,
                repository: context.read<PlacesRepository>(),
                media: context.read<MediaRepository>(),
                crashReporter: context.read<CrashReporter>(),
              ),
            ),
            BlocProvider<CatalogViewCubit>(
              create: (BuildContext context) => CatalogViewCubit(
                uid: uid,
                settings: context.read<SettingsRepository>(),
              ),
            ),
            BlocProvider<ProfileBloc>(
              create: (BuildContext context) => ProfileBloc(
                auth: context.read<AuthRepository>(),
                analytics: context.read<AnalyticsService>(),
                profiles: context.read<UserProfileRepository>(),
                media: context.read<MediaRepository>(),
              )..add(const ProfileStarted()),
            ),
          ],
          child: child,
        );
      },
    );
  }

  static String? _uid(AuthState state) =>
      state is Authenticated ? state.user.uid : null;
}
```

