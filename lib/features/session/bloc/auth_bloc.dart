import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/auth_failure.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// The session of the whole app: who is signed in, if anybody.
///
/// It turns the repository's `authStateChanges()` stream into states, so
/// `AuthGate` is just `BlocBuilder<AuthBloc, AuthState>` — UI = f(state).
/// Firebase keeps the session on the device, which is why a restart goes
/// `AuthInitial` → `Authenticated` without showing Login (session restore).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._auth)
    // `currentUser` is known synchronously when the SDK has already
    // restored the session; otherwise the splash waits for the stream.
    : super(_initial(_auth.currentUser)) {
    on<AuthStarted>(_onStarted);
    on<AuthLogoutRequested>(_onLogout);
  }

  final AuthRepository _auth;

  static AuthState _initial(AppUser? user) =>
      user == null ? const AuthInitial() : Authenticated(user);

  /// `emit.forEach` keeps listening until the bloc closes and cancels the
  /// subscription itself — no manual `StreamSubscription` to leak.
  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) {
    return emit.forEach<AppUser?>(
      _auth.authStateChanges(),
      onData: (AppUser? user) =>
          user == null ? const Unauthenticated() : Authenticated(user),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Clear an old error first, so a repeated failure is a new state.
    if (state case Authenticated(:final user, logoutError: != null)) {
      emit(Authenticated(user));
    }
    final AuthState current = state;
    try {
      // The auth stream then emits `Unauthenticated`; this only asks.
      await _auth.signOut();
    } on AuthFailure catch (failure) {
      if (current is Authenticated) {
        emit(Authenticated(current.user, logoutError: failure.message));
      }
    }
  }
}
