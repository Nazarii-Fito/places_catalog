import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/auth_failure.dart';
import '../models/app_user.dart';
import '../services/crash_reporter.dart';
import 'auth_repository.dart';

/// [AuthRepository] implemented with Firebase Auth + Google Sign-In 7.x.
///
/// This is the only place in the app that imports `firebase_auth`.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required CrashReporter crashReporter,
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  }) : _crash = crashReporter,
       _auth = auth ?? FirebaseAuth.instance,
       _google = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  final CrashReporter _crash;

  /// `GoogleSignIn.initialize` must run exactly once before `authenticate`.
  Future<void>? _googleInit;

  /// Google credential rejected with account-exists, waiting to be linked.
  AuthCredential? _pendingGoogleCredential;

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_toApp);

  @override
  Stream<AppUser?> userChanges() => _auth.userChanges().map(_toApp);

  @override
  AppUser? get currentUser => _toApp(_auth.currentUser);

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) => _guard('signUp', () async {
    final UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final User user = result.user!;
    await user.updateDisplayName(fullName);
    // reload + userChanges() lets Profile show the name right away.
    await user.reload();
  });

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard('signIn', () async {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      });

  @override
  Future<bool> signInWithGoogle() => _guard('signInWithGoogle', () async {
    final AuthCredential? credential = await _googleCredential();
    if (credential == null) return false;
    try {
      await _auth.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        _pendingGoogleCredential = e.credential ?? credential;
      }
      rethrow;
    }
  });

  @override
  Future<void> completeGoogleLink({
    required String email,
    required String password,
  }) => _guard('completeGoogleLink', () async {
    final AuthCredential? pending = _pendingGoogleCredential;
    final UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (pending != null) {
      await result.user!.linkWithCredential(pending);
      _pendingGoogleCredential = null;
    }
  });

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _guard('sendPasswordResetEmail', () async {
        await _auth.sendPasswordResetEmail(email: email);
      });

  @override
  Future<void> reauthenticate({required String currentPassword}) =>
      _guard('reauthenticate', () => _reauthenticate(currentPassword));

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _guard('changePassword', () async {
    await _reauthenticate(currentPassword);
    await _requireUser().updatePassword(newPassword);
  });

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) =>
      _guard('updateProfile', () async {
        final User user = _requireUser();
        if (displayName != null) await user.updateDisplayName(displayName);
        if (photoUrl != null) await user.updatePhotoURL(photoUrl);
        await user.reload();
      });

  @override
  Future<bool> linkGoogle() => _guard('linkGoogle', () async {
    final AuthCredential? credential = await _googleCredential();
    if (credential == null) return false;
    await _requireUser().linkWithCredential(credential);
    await _requireUser().reload();
    return true;
  });

  @override
  Future<void> signOut() => _guard('signOut', () async {
    await _auth.signOut();
    if (_googleInit != null) await _google.signOut();
  });

  // ---------------------------------------------------------------------

  Future<void> _reauthenticate(String currentPassword) async {
    final User user = _requireUser();
    final AuthCredential credential = EmailAuthProvider.credential(
      email: user.email ?? '',
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
  }

  User _requireUser() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure(AuthFailureType.requiresRecentLogin);
    }
    return user;
  }

  /// Runs the Google sheet and converts its ID token into a Firebase
  /// credential. `null` means the user closed the sheet.
  Future<AuthCredential?> _googleCredential() async {
    await (_googleInit ??= _google.initialize());
    try {
      final GoogleSignInAccount account = await _google.authenticate();
      final String? idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(AuthFailureType.googleUnavailable);
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  /// Converts every SDK error into [AuthFailure]. Unknown codes and
  /// unexpected errors are sent to Crashlytics as non-fatal.
  Future<T> _guard<T>(String action, Future<T> Function() body) async {
    await _crash.log('Auth: $action');
    try {
      return await body();
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e, stack) {
      final AuthFailure failure = AuthFailure.fromCode(e.code, email: e.email);
      if (failure.isUnknown) {
        await _crash.recordError(e, stack, reason: 'Auth $action: ${e.code}');
      }
      throw failure;
    } on GoogleSignInException catch (e, stack) {
      await _crash.recordError(e, stack, reason: 'Google $action: ${e.code}');
      throw const AuthFailure(AuthFailureType.googleUnavailable);
    } catch (e, stack) {
      await _crash.recordError(e, stack, reason: 'Auth $action failed');
      throw const AuthFailure(AuthFailureType.unknown);
    }
  }

  static AppUser? _toApp(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      providerIds: {
        for (final UserInfo info in user.providerData) info.providerId,
      },
    );
  }
}
