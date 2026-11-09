part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

/// Waiting for Firebase to restore the session: the splash is shown.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user, {this.logoutError});

  final AppUser user;

  /// Set when "Log Out" failed; the Profile screen shows it once.
  final String? logoutError;

  @override
  List<Object?> get props => [user.uid, logoutError];
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}
