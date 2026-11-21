// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/places_failure.dart';
import '../../../data/models/place.dart';
import '../../../data/models/place_photo.dart';
import '../../../data/repositories/media_repository.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/services/crash_reporter.dart';
import '../../../data/services/photo_upload_session.dart';

part 'update_place_event.dart';
part 'update_place_state.dart';

/// Saves an edited place: **new photos to storage → document → delete the
/// removed photos' files**.
///
/// * Unchanged photos are kept as they are — never uploaded again.
/// * New photos (local files) are uploaded first; if the document write then
///   fails, they are rolled back, so nothing is half-saved.
/// * Files of removed photos are deleted only *after* the document no longer
///   references them. That delete is best-effort: a failure leaves an
///   orphan file (logged) but never fails the user's save.
class UpdatePlaceBloc extends Bloc<UpdatePlaceEvent, UpdatePlaceState> {
  UpdatePlaceBloc({
    required this.uid,
    required PlacesRepository repository,
    required MediaRepository media,
    required CrashReporter crashReporter,
  }) : _repository = repository,
       _media = media,
       _crashReporter = crashReporter,
       super(const UpdatePlaceIdle()) {
    on<UpdatePlaceSubmitted>(_onSubmitted);
    on<UpdatePlaceReset>((_, Emitter<UpdatePlaceState> emit) {
      if (state is! PlaceUpdatingState) emit(const UpdatePlaceIdle());
    });
  }

  final String uid;
  final PlacesRepository _repository;
  final MediaRepository _media;
  final CrashReporter _crashReporter;

  Future<void> _onSubmitted(
    UpdatePlaceSubmitted event,
    Emitter<UpdatePlaceState> emit,
  ) async {
    if (state is PlaceUpdatingState) return;
    final UpdateOrigin origin = event.origin;
    final int total = event.draft.photos
        .where((PlacePhoto p) => p.isLocal)
        .length;
    emit(PlaceUpdatingState(total: total, origin: origin));

    final PhotoUploadSession session = PhotoUploadSession(
      media: _media,
      crashReporter: _crashReporter,
      uid: uid,
      placeId: event.original.id,
    );
    try {
      final List<PlacePhoto> photos = await session.upload(
        event.draft.photos,
        onProgress: (int uploaded, int total) {
          if (!isClosed) {
            emit(
              PlaceUpdatingState(
                uploaded: uploaded,
                total: total,
                origin: origin,
              ),
            );
          }
        },
      );
      final Place place = event.draft.copyWith(
        id: event.original.id,
        photos: photos,
        coverImage: photos.isNotEmpty ? photos.first : null,
      );
      await _repository.savePlace(uid, place);
      emit(PlaceUpdateSuccessState(place, origin: origin));
      await _deleteRemoved(event.original, place);
    } on PlacesFailure catch (failure) {
      await session.rollback();
      emit(
        PlaceUpdateErrorState(
          message: failure.message,
          retryable: failure.isRetryable,
          origin: origin,
        ),
      );
    } catch (error, stack) {
      await session.rollback();
      await _crashReporter.recordError(error, stack, reason: 'Update place');
      emit(
        PlaceUpdateErrorState(
          message: const PlacesFailure(PlacesFailureType.unknown).message,
          retryable: true,
          origin: origin,
        ),
      );
    }
  }

  /// Deletes the stored files the saved place no longer references.
  Future<void> _deleteRemoved(Place original, Place saved) async {
    final Set<String> kept = {
      for (final PlacePhoto p in saved.photos)
        if (p.storagePath != null) p.storagePath!,
    };
    final List<String> removed = [
      for (final PlacePhoto p in original.photos)
        if (p.storagePath != null && !kept.contains(p.storagePath))
          p.storagePath!,
    ];
    if (removed.isEmpty) return;
    try {
      await _media.deleteAll(removed);
    } catch (error, stack) {
      await _crashReporter.recordError(
        error,
        stack,
        reason: 'Deleting ${removed.length} removed photos failed (orphans)',
      );
    }
  }
}
