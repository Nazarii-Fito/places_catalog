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

part 'create_place_event.dart';
part 'create_place_state.dart';

/// Creates a place: **id → photos to storage → document to the database**.
///
/// Order matters. The id is allocated first because the photos are stored
/// under `users/<uid>/<placeId>/`. The document is written last and only
/// with the final photo URLs, so there is never a record pointing at files
/// that failed to upload. If anything fails after some photos are already
/// uploaded, those files are deleted again (rollback) and the error is
/// reported; the user can retry.
class CreatePlaceBloc extends Bloc<CreatePlaceEvent, CreatePlaceState> {
  CreatePlaceBloc({
    required this.uid,
    required PlacesRepository repository,
    required MediaRepository media,
    required CrashReporter crashReporter,
  }) : _repository = repository,
       _media = media,
       _crashReporter = crashReporter,
       super(const CreatePlaceIdle()) {
    on<CreatePlaceSubmitted>(_onSubmitted);
    on<CreatePlaceReset>((_, Emitter<CreatePlaceState> emit) {
      // Never wipe a save that is still running.
      if (state is! PlaceCreatingState) emit(const CreatePlaceIdle());
    });
  }

  final String uid;
  final PlacesRepository _repository;
  final MediaRepository _media;
  final CrashReporter _crashReporter;

  Future<void> _onSubmitted(
    CreatePlaceSubmitted event,
    Emitter<CreatePlaceState> emit,
  ) async {
    // A second tap while saving must not start a second save.
    if (state is PlaceCreatingState) return;
    final int total = event.draft.photos
        .where((PlacePhoto p) => p.isLocal)
        .length;
    emit(PlaceCreatingState(total: total));

    final String placeId = _repository.newPlaceId(uid);
    final PhotoUploadSession session = PhotoUploadSession(
      media: _media,
      crashReporter: _crashReporter,
      uid: uid,
      placeId: placeId,
    );
    try {
      final List<PlacePhoto> photos = await session.upload(
        event.draft.photos,
        onProgress: (int uploaded, int total) {
          if (!isClosed) {
            emit(PlaceCreatingState(uploaded: uploaded, total: total));
          }
        },
      );
      final Place place = event.draft.copyWith(
        id: placeId,
        photos: photos,
        // The card thumbnail is the first photo, now its uploaded copy.
        coverImage: photos.isNotEmpty ? photos.first : null,
      );
      await _repository.savePlace(uid, place);
      emit(PlaceCreateSuccessState(place));
    } on PlacesFailure catch (failure) {
      await session.rollback();
      emit(
        PlaceCreateErrorState(
          message: failure.message,
          retryable: failure.isRetryable,
        ),
      );
    } catch (error, stack) {
      await session.rollback();
      await _crashReporter.recordError(error, stack, reason: 'Create place');
      emit(
        PlaceCreateErrorState(
          message: const PlacesFailure(PlacesFailureType.unknown).message,
          retryable: true,
        ),
      );
    }
  }
}
