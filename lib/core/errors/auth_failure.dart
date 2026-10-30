import '../constants/app_strings.dart';

/// Kinds of authentication errors the UI distinguishes.
enum AuthFailureType {
  invalidEmail,
  invalidCredentials,
  userDisabled,
  emailAlreadyInUse,
  weakPassword,
  tooManyRequests,
  network,
  requiresRecentLogin,
  operationNotAllowed,

  /// Google sign-in for an e-mail that already has a password account —
  /// the UI asks for the password and links both methods.
  accountExistsWithDifferentCredential,
  credentialAlreadyInUse,
  providerAlreadyLinked,
  googleUnavailable,
  appleUnavailable,
  unknown,
}

/// Error thrown by `AuthRepository` instead of raw SDK exceptions, so the
/// UI shows a clear message and never the exception text.
class AuthFailure implements Exception {
  const AuthFailure(this.type, {this.code, this.email});

  /// Maps a `FirebaseAuthException.code` to a failure type.
  factory AuthFailure.fromCode(String code, {String? email}) {
    final AuthFailureType type = switch (code) {
      'invalid-email' => AuthFailureType.invalidEmail,
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'INVALID_LOGIN_CREDENTIALS' => AuthFailureType.invalidCredentials,
      'user-disabled' => AuthFailureType.userDisabled,
      'email-already-in-use' => AuthFailureType.emailAlreadyInUse,
      'weak-password' => AuthFailureType.weakPassword,
      'too-many-requests' => AuthFailureType.tooManyRequests,
      'network-request-failed' => AuthFailureType.network,
      'requires-recent-login' ||
      'user-token-expired' => AuthFailureType.requiresRecentLogin,
      'operation-not-allowed' => AuthFailureType.operationNotAllowed,
      'account-exists-with-different-credential' =>
        AuthFailureType.accountExistsWithDifferentCredential,
      'credential-already-in-use' ||
      'email-already-linked' => AuthFailureType.credentialAlreadyInUse,
      'provider-already-linked' => AuthFailureType.providerAlreadyLinked,
      _ => AuthFailureType.unknown,
    };
    return AuthFailure(type, code: code, email: email);
  }

  final AuthFailureType type;

  /// Original SDK code, kept for Crashlytics — never shown to the user.
  final String? code;

  /// E-mail of the existing account (for account-exists linking).
  final String? email;

  bool get isUnknown => type == AuthFailureType.unknown;

  /// User-facing text for this failure.
  String get message => switch (type) {
    AuthFailureType.invalidEmail => AppStrings.errorInvalidEmail,
    AuthFailureType.invalidCredentials => AppStrings.errorInvalidCredentials,
    AuthFailureType.userDisabled => AppStrings.errorUserDisabled,
    AuthFailureType.emailAlreadyInUse => AppStrings.errorEmailInUse,
    AuthFailureType.weakPassword => AppStrings.errorWeakPassword,
    AuthFailureType.tooManyRequests => AppStrings.errorTooManyRequests,
    AuthFailureType.network => AppStrings.errorNetwork,
    AuthFailureType.requiresRecentLogin => AppStrings.errorRecentLogin,
    AuthFailureType.operationNotAllowed => AppStrings.errorNotAllowed,
    AuthFailureType.accountExistsWithDifferentCredential =>
      AppStrings.errorAccountExists,
    AuthFailureType.credentialAlreadyInUse => AppStrings.errorCredentialInUse,
    AuthFailureType.providerAlreadyLinked => AppStrings.errorAlreadyLinked,
    AuthFailureType.googleUnavailable => AppStrings.errorGoogleUnavailable,
    AuthFailureType.appleUnavailable => AppStrings.errorAppleUnavailable,
    AuthFailureType.unknown => AppStrings.errorUnknown,
  };

  @override
  String toString() => 'AuthFailure($type, code: $code)';
}
