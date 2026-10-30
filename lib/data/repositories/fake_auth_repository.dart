import 'dart:async';

import '../../core/errors/auth_failure.dart';
import '../models/app_user.dart';
import 'auth_repository.dart';

/// In-memory [AuthRepository] for widget tests and the screenshot mode.
///
/// Set [nextFailure] to make the next call fail, or [gate] to keep a call
/// pending (to test the loading state). [calls] records method names.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? signedInAs}) : _user = signedInAs;

  /// A ready-made signed-in user (email + Google linked).
  factory FakeAuthRepository.signedIn() => FakeAuthRepository(
    signedInAs: const AppUser(
      uid: 'demo-uid',
      email: 'nazarii.fito@gmail.com',
      displayName: 'Nazarii Fito',
      providerIds: {AppUser.passwordProvider},
    ),
  );

  AppUser? _user;
  final StreamController<AppUser?> _changes =
      StreamController<AppUser?>.broadcast();

  final List<String> calls = [];
  AuthFailure? nextFailure;
  Completer<void>? gate;

  @override
  Stream<AppUser?> authStateChanges() => _stream();

  @override
  Stream<AppUser?> userChanges() => _stream();

  Stream<AppUser?> _stream() async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  AppUser? get currentUser => _user;

  Future<void> _run(String name, void Function() effect) async {
    calls.add(name);
    final Completer<void>? pending = gate;
    if (pending != null) await pending.future;
    final AuthFailure? failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      throw failure;
    }
    effect();
  }

  void _emit(AppUser? user) {
    _user = user;
    _changes.add(user);
  }

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) => _run(
    'signUp',
    () => _emit(
      AppUser(
        uid: 'fake-$email',
        email: email,
        displayName: fullName,
        providerIds: const {AppUser.passwordProvider},
      ),
    ),
  );

  @override
  Future<void> signIn({required String email, required String password}) =>
      _run(
        'signIn',
        () => _emit(
          AppUser(
            uid: 'fake-$email',
            email: email,
            providerIds: const {AppUser.passwordProvider},
          ),
        ),
      );

  @override
  Future<bool> signInWithGoogle() async {
    await _run(
      'signInWithGoogle',
      () => _emit(
        const AppUser(
          uid: 'fake-google',
          email: 'google.user@gmail.com',
          displayName: 'Google User',
          providerIds: {AppUser.googleProvider},
        ),
      ),
    );
    return true;
  }

  @override
  Future<bool> signInWithApple() async {
    await _run(
      'signInWithApple',
      () => _emit(
        const AppUser(
          uid: 'fake-apple',
          email: 'apple.user@privaterelay.appleid.com',
          displayName: 'Apple User',
          providerIds: {AppUser.appleProvider},
        ),
      ),
    );
    return true;
  }

  @override
  Future<void> completeGoogleLink({
    required String email,
    required String password,
  }) => _run(
    'completeGoogleLink',
    () => _emit(
      AppUser(
        uid: 'fake-$email',
        email: email,
        providerIds: const {AppUser.passwordProvider, AppUser.googleProvider},
      ),
    ),
  );

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _run('sendPasswordResetEmail', () {});

  @override
  Future<void> reauthenticate({required String currentPassword}) =>
      _run('reauthenticate', () {});

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _run('changePassword', () {});

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) =>
      _run('updateProfile', () {
        final AppUser? user = _user;
        if (user == null) return;
        _emit(
          AppUser(
            uid: user.uid,
            email: user.email,
            displayName: displayName ?? user.displayName,
            photoUrl: photoUrl ?? user.photoUrl,
            providerIds: user.providerIds,
          ),
        );
      });

  @override
  Future<bool> linkGoogle() async {
    await _run('linkGoogle', () {
      final AppUser? user = _user;
      if (user == null) return;
      _emit(
        AppUser(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          providerIds: {...user.providerIds, AppUser.googleProvider},
        ),
      );
    });
    return true;
  }

  @override
  Future<void> signOut() => _run('signOut', () => _emit(null));
}
