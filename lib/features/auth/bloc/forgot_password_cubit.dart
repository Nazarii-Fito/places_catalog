// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/auth_failure.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/analytics_service.dart';

enum ForgotPasswordStatus { idle, submitting, sent, failure }

final class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.idle,
    this.message,
  });

  final ForgotPasswordStatus status;
  final String? message;

  @override
  List<Object?> get props => [status, message];
}

/// A Cubit: one action ("send the link") and a plain state, so event
/// classes would only add boilerplate.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit({
    required AuthRepository auth,
    required AnalyticsService analytics,
  }) : _auth = auth,
       _analytics = analytics,
       super(const ForgotPasswordState());

  final AuthRepository _auth;
  final AnalyticsService _analytics;

  Future<void> sendLink(String email) async {
    if (state.status == ForgotPasswordStatus.submitting) return;
    emit(const ForgotPasswordState(status: ForgotPasswordStatus.submitting));
    try {
      await _auth.sendPasswordResetEmail(email: email);
      await _analytics.logPasswordResetRequested();
      emit(const ForgotPasswordState(status: ForgotPasswordStatus.sent));
    } on AuthFailure catch (failure) {
      emit(
        ForgotPasswordState(
          status: ForgotPasswordStatus.failure,
          message: failure.message,
        ),
      );
    }
  }

  /// "Resend": back to the form.
  void reset() => emit(const ForgotPasswordState());
}
