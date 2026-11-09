// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/auth_failure.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/analytics_service.dart';

part 'login_event.dart';
part 'login_state.dart';

/// Sign-in with e-mail/password, Google and Apple.
///
/// While a request runs ([LoginLoading]) every new event is ignored, so a
/// second tap can never send a second request. A *successful* sign-in does
/// not navigate: `AuthBloc` sees the new session and `AuthGate` switches the
/// screen. [LoginSuccess] exists so the UI and tests can tell it happened.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required AuthRepository auth, required AnalyticsService analytics})
    : _auth = auth,
      _analytics = analytics,
      super(const LoginInitial()) {
    on<LoginSubmitted>(_onSubmitted);
    on<LoginGoogleRequested>(_onGoogle);
    on<LoginAppleRequested>(_onApple);
    on<LoginGoogleLinkConfirmed>(_onLinkConfirmed);
    on<LoginGoogleLinkCancelled>((_, Emitter<LoginState> emit) {
      emit(const LoginInitial());
    });
  }

  final AuthRepository _auth;
  final AnalyticsService _analytics;

  bool get _busy => state is LoginLoading;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (_busy) return;
    emit(const LoginLoading());
    try {
      await _auth.signIn(email: event.email, password: event.password);
      await _analytics.logLogin('password');
      emit(const LoginSuccess());
    } on AuthFailure catch (failure) {
      emit(LoginFailure(failure.message));
    }
  }

  Future<void> _onGoogle(
    LoginGoogleRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (_busy) return;
    emit(const LoginLoading());
    try {
      final bool signedIn = await _auth.signInWithGoogle();
      if (!signedIn) return emit(const LoginInitial()); // sheet dismissed
      await _analytics.logLogin('google');
      emit(const LoginSuccess());
    } on AuthFailure catch (failure) {
      final String? email = failure.email;
      if (failure.type ==
              AuthFailureType.accountExistsWithDifferentCredential &&
          email != null) {
        // The e-mail already has a password account: ask for the password
        // (the UI listens for this state) and link Google to it.
        emit(LoginLinkRequired(email));
      } else {
        emit(LoginFailure(failure.message));
      }
    }
  }

  Future<void> _onApple(
    LoginAppleRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (_busy) return;
    emit(const LoginLoading());
    try {
      final bool signedIn = await _auth.signInWithApple();
      if (!signedIn) return emit(const LoginInitial());
      await _analytics.logLogin('apple');
      emit(const LoginSuccess());
    } on AuthFailure catch (failure) {
      emit(LoginFailure(failure.message));
    }
  }

  Future<void> _onLinkConfirmed(
    LoginGoogleLinkConfirmed event,
    Emitter<LoginState> emit,
  ) async {
    if (_busy) return;
    emit(const LoginLoading());
    try {
      await _auth.completeGoogleLink(
        email: event.email,
        password: event.password,
      );
      await _analytics.logAccountLinked('google.com');
      emit(const LoginSuccess());
    } on AuthFailure catch (failure) {
      emit(LoginFailure(failure.message));
    }
  }
}
