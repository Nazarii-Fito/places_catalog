part of 'login_bloc.dart';

sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => const [];
}

final class LoginInitial extends LoginState {
  const LoginInitial();
}

/// A request is running: buttons show a spinner, fields are read-only.
final class LoginLoading extends LoginState {
  const LoginLoading();
}

final class LoginSuccess extends LoginState {
  const LoginSuccess();
}

final class LoginFailure extends LoginState {
  const LoginFailure(this.message);

  /// Human-readable text from [AuthFailure.message], shown in the banner.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Google sign-in hit an e-mail that already has a password account.
final class LoginLinkRequired extends LoginState {
  const LoginLinkRequired(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}
