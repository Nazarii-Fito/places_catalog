import '../models/app_user.dart';

/// Everything the app needs from authentication.
///
/// Screens depend on this interface only — never on `firebase_auth` — so
/// the backend can be swapped (e.g. `FakeAuthRepository` in tests and the
/// screenshot mode). Every method throws `AuthFailure` on error.
abstract interface class AuthRepository {
  /// Emits on sign-in / sign-out; drives `AuthGate` and session restore.
  Stream<AppUser?> authStateChanges();

  /// Also emits after profile changes (name, photo, linked providers).
  Stream<AppUser?> userChanges();

  AppUser? get currentUser;

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signIn({required String email, required String password});

  /// Returns `false` when the user cancels the Google sheet (not an error).
  /// Throws `AuthFailureType.accountExistsWithDifferentCredential` when the
  /// e-mail already has a password account — see [completeGoogleLink].
  Future<bool> signInWithGoogle();

  /// Native Sign in with Apple (iOS). Returns `false` when the user cancels.
  /// Apple shares the name only on the first sign-in, so it is saved then.
  Future<bool> signInWithApple();

  /// Signs in with the existing password account and links the Google
  /// credential that was rejected by [signInWithGoogle].
  Future<void> completeGoogleLink({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> reauthenticate({required String currentPassword});

  /// Re-authenticates with [currentPassword], then sets [newPassword].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> updateProfile({String? displayName, String? photoUrl});

  /// Links Google to the signed-in account. `false` if cancelled.
  Future<bool> linkGoogle();

  Future<void> signOut();
}
