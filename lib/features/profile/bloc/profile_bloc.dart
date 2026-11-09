// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/auth_failure.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/analytics_service.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// The signed-in user's profile: shows it (from `userChanges()`), edits
/// name/photo and links Google. One instance per user (see `UserScope`).
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required AuthRepository auth,
    required AnalyticsService analytics,
  }) : _auth = auth,
       _analytics = analytics,
       // The current user is known synchronously, so the first frame is
       // already filled in; the stream then keeps it up to date.
       super(
         ProfileState(
           user: auth.currentUser,
           status: auth.currentUser == null
               ? ProfileStatus.loading
               : ProfileStatus.idle,
         ),
       ) {
    on<ProfileStarted>(_onStarted);
    on<ProfileUpdated>(_onUpdated);
    on<ProfileGoogleLinkRequested>(_onLinkGoogle);
    on<ProfileErrorDismissed>((_, Emitter<ProfileState> emit) {
      emit(state.copyWith(status: ProfileStatus.idle, clearMessage: true));
    });
  }

  final AuthRepository _auth;
  final AnalyticsService _analytics;

  Future<void> _onStarted(ProfileStarted event, Emitter<ProfileState> emit) {
    return emit.forEach<AppUser?>(
      _auth.userChanges(),
      onData: (AppUser? user) => state.copyWith(
        user: user,
        status: state.status == ProfileStatus.loading
            ? ProfileStatus.idle
            : state.status,
      ),
    );
  }

  Future<void> _onUpdated(
    ProfileUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.status == ProfileStatus.saving) return;
    emit(state.copyWith(status: ProfileStatus.saving, clearMessage: true));
    try {
      await _auth.updateProfile(
        displayName: event.displayName,
        photoUrl: event.photoUrl,
      );
      await _analytics.logProfileUpdated(photoSource: event.photoSource);
      // saving → idle is the "saved" signal the Edit Profile screen waits for.
      emit(state.copyWith(status: ProfileStatus.idle));
    } on AuthFailure catch (failure) {
      emit(
        state.copyWith(
          status: ProfileStatus.saveFailure,
          message: failure.message,
        ),
      );
    }
  }

  Future<void> _onLinkGoogle(
    ProfileGoogleLinkRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.status == ProfileStatus.linking) return;
    emit(state.copyWith(status: ProfileStatus.linking, clearMessage: true));
    try {
      final bool linked = await _auth.linkGoogle();
      if (linked) await _analytics.logAccountLinked('google.com');
      emit(state.copyWith(status: ProfileStatus.idle));
    } on AuthFailure catch (failure) {
      emit(
        state.copyWith(
          status: ProfileStatus.linkFailure,
          message: failure.message,
        ),
      );
    }
  }
}
