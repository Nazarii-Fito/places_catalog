// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/auth_failure.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/analytics_service.dart';

part 'register_event.dart';
part 'register_state.dart';

/// Creates an account with e-mail and password. Same contract as
/// `LoginBloc`: events are ignored while loading, and the new session —
/// not this bloc — switches the screen.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({
    required AuthRepository auth,
    required AnalyticsService analytics,
  }) : _auth = auth,
       _analytics = analytics,
       super(const RegisterInitial()) {
    on<RegisterSubmitted>(_onSubmitted);
  }

  final AuthRepository _auth;
  final AnalyticsService _analytics;

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    if (state is RegisterLoading) return;
    emit(const RegisterLoading());
    try {
      await _auth.signUp(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
      );
      await _analytics.logSignUp('password');
      emit(const RegisterSuccess());
    } on AuthFailure catch (failure) {
      emit(RegisterFailure(failure.message));
    }
  }
}
