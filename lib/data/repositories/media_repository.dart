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
  Future<void> deletePhoto(String storagePath) async {}

  @override
  Future<void> deleteAll(List<String> storagePaths) async {}
}
