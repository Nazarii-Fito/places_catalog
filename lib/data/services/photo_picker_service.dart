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
