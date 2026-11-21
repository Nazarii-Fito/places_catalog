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
  }) : _storage = client.storage.from(bucket),
       _crashReporter = crashReporter,
       _uuid = uuid;

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
  }) async {
    final String contentType = local.contentType ?? 'image/jpeg';
    final String path = buildPath(
      uid: uid,
      placeId: placeId,
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
