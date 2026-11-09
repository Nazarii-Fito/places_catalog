part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => const [];
}

final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class LoginGoogleRequested extends LoginEvent {
  const LoginGoogleRequested();
}

final class LoginAppleRequested extends LoginEvent {
  const LoginAppleRequested();
}

/// The user typed the password of the existing account in the link dialog.
final class LoginGoogleLinkConfirmed extends LoginEvent {
  const LoginGoogleLinkConfirmed({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class LoginGoogleLinkCancelled extends LoginEvent {
  const LoginGoogleLinkCancelled();
}
