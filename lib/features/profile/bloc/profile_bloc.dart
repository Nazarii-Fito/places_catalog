// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/auth_failure.dart';
import '../../../data/models/app_user.dart';
import '../../../core/errors/places_failure.dart';
import '../../../data/models/place_photo.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/media_repository.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../data/services/analytics_service.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// The signed-in user's profile: shows it (from `userChanges()`), edits
/// name/photo and links Google. One instance per user (see `UserScope`).
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required AuthRepository auth,
    required AnalyticsService analytics,
    required UserProfileRepository profiles,
    required MediaRepository media,
  }) : _auth = auth,
       _analytics = analytics,
       _profiles = profiles,
       _media = media,
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
  final UserProfileRepository _profiles;
  final MediaRepository _media;

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

    final AppUser? before = _auth.currentUser;
    final String? oldPhotoUrl = before?.photoUrl;
    PlacePhoto? uploaded;
    try {
      String? photoUrl = event.photoUrl;
      final PlacePhoto? picked = event.newAvatar;
      if (picked != null && before != null) {
        // The picture goes to cloud storage first; its public URL becomes
        // the account's `photoURL`.
        uploaded = await _media.uploadAvatar(uid: before.uid, local: picked);
        photoUrl = uploaded.location;
      }
      await _auth.updateProfile(
        displayName: event.displayName,
        photoUrl: photoUrl,
      );
      await _analytics.logProfileUpdated(photoSource: event.photoSource);
      final AppUser? updated = _auth.currentUser;
      // Mirror the new name/photo into `users/{uid}` (best-effort).
      if (updated != null) unawaited(_profiles.syncProfile(updated));
      // saving → idle is the "saved" signal the Edit Profile screen waits for.
      emit(state.copyWith(status: ProfileStatus.idle));
      // The previous picture, if it was one of ours, is no longer used.
      if (photoUrl != null && photoUrl != oldPhotoUrl) {
        await _deleteOwnFile(oldPhotoUrl);
      }
    } on AuthFailure catch (failure) {
      // The account was not changed: the file just uploaded is orphaned.
      await _deleteOwnFile(uploaded?.location);
      emit(
        state.copyWith(
          status: ProfileStatus.saveFailure,
          message: failure.message,
        ),
      );
    } on PlacesFailure catch (failure) {
      emit(
        state.copyWith(
          status: ProfileStatus.saveFailure,
          message: failure.message,
        ),
      );
    }
  }

  /// Deletes [url]'s file when it lives in our bucket. Best-effort: an
  /// orphan file is acceptable, a failed save because of it is not.
  Future<void> _deleteOwnFile(String? url) async {
    if (url == null) return;
    final String? path = _media.storagePathOf(url);
    if (path == null) return;
    try {
      await _media.deletePhoto(path);
    } catch (_) {
      // Left behind; nothing to tell the user.
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
