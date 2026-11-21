import 'dart:async';

import '../../core/errors/places_failure.dart';
import '../models/place_photo.dart';
import 'media_repository.dart';

/// In-memory [MediaRepository] for tests and the screenshot mode: nothing
/// leaves the device. Records what happened and can be told to fail.
class FakeMediaRepository implements MediaRepository {
  FakeMediaRepository({this.configured = true});

  final bool configured;

  /// Upload number (1-based) that fails, e.g. `3` fails the third file.
  int? failOnUpload;
  PlacesFailure failure = const PlacesFailure(PlacesFailureType.offline);

  /// Delete requests fail too (to prove they never block a save).
  bool failDeletes = false;

  /// While set, uploads wait for it (to test "a second tap is ignored").
  Completer<void>? gate;

  final List<String> uploaded = [];
  final List<String> deleted = [];
  int _uploads = 0;

  @override
  bool get isConfigured => configured;

  @override
  Future<PlacePhoto> uploadPlacePhoto({
    required String uid,
    required String placeId,
    required PlacePhoto local,
  }) async {
    if (!configured) {
      throw const PlacesFailure(PlacesFailureType.storageNotConfigured);
    }
    _uploads++;
    await gate?.future;
    if (failOnUpload == _uploads) throw failure;
    final String path = 'users/$uid/$placeId/fake-$_uploads.jpg';
    uploaded.add(path);
    return PlacePhoto.remote(
      url: 'https://fake.invalid/place-photos/$path',
      storagePath: path,
      fileSizeBytes: local.fileSizeBytes,
      contentType: local.contentType ?? 'image/jpeg',
      uploadedAt: DateTime.utc(2026, 11, 20),
    );
  }

  @override
  Future<void> deletePhoto(String storagePath) async {
    if (failDeletes) throw failure;
    deleted.add(storagePath);
  }

  @override
  Future<void> deleteAll(List<String> storagePaths) async {
    if (failDeletes) throw failure;
    deleted.addAll(storagePaths);
  }
}
