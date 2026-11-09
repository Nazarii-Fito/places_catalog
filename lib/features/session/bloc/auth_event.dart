part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Start listening to the session (sent once, when the bloc is created).
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// The user confirmed "Log Out".
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
