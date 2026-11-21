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
