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
