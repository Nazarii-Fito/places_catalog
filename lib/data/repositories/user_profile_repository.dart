import '../models/app_user.dart';

/// Keeps a copy of the signed-in user's profile in the cloud database
/// (`users/{uid}`), next to their catalog.
///
/// Firebase Auth owns the account; this mirror exists so profile data can
/// be read together with the user's other documents (FR2). It is
/// best-effort: a failure is reported, never shown, and never blocks sign-in.
abstract interface class UserProfileRepository {
  Future<void> syncProfile(AppUser user);
}

/// Does nothing: tests, screenshot mode and the local-file backend.
class NoopUserProfileRepository implements UserProfileRepository {
  const NoopUserProfileRepository();

  @override
  Future<void> syncProfile(AppUser user) async {}
}

/// The fields mirrored into `users/{uid}`. Timestamps (`createdAt`,
/// `lastLoginAt`) are added by the Firestore implementation.
Map<String, Object?> userProfileFields(AppUser user) => {
  'displayName': user.displayName,
  'email': user.email,
  'photoUrl': user.photoUrl,
};
