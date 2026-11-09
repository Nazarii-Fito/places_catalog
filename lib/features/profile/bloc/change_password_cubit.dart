// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/auth_failure.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/analytics_service.dart';

enum ChangePasswordStatus { idle, submitting, success, failure }

final class ChangePasswordState extends Equatable {
  const ChangePasswordState({
    this.status = ChangePasswordStatus.idle,
    this.failureType,
    this.message,
  });

  final ChangePasswordStatus status;

  /// Tells the UI *where* to show the error: under the current-password
  /// field, in a "log in again" dialog, or in the generic banner.
  final AuthFailureType? failureType;
  final String? message;

  @override
  List<Object?> get props => [status, failureType, message];
}

/// A Cubit on purpose (see `CatalogViewCubit`): one method, four states.
/// Re-authentication with the current password happens inside the
/// repository; `requires-recent-login` is reported as a failure type.
class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit({
    required AuthRepository auth,
    required AnalyticsService analytics,
  }) : _auth = auth,
       _analytics = analytics,
       super(const ChangePasswordState());

  final AuthRepository _auth;
  final AnalyticsService _analytics;

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.status == ChangePasswordStatus.submitting) return;
    emit(const ChangePasswordState(status: ChangePasswordStatus.submitting));
    try {
      await _auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      await _analytics.logPasswordChanged();
      emit(const ChangePasswordState(status: ChangePasswordStatus.success));
    } on AuthFailure catch (failure) {
      emit(
        ChangePasswordState(
          status: ChangePasswordStatus.failure,
          failureType: failure.type,
          message: failure.message,
        ),
      );
    }
  }

  /// Forgets a shown error (e.g. the user starts retyping the field).
  void clearError() {
    if (state.status == ChangePasswordStatus.failure) {
      emit(const ChangePasswordState());
    }
  }
}
