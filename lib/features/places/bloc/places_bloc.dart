// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/places_failure.dart';
import '../../../data/models/place.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/crash_reporter.dart';

part 'places_event.dart';
part 'places_state.dart';

/// Owns the catalog of one signed-in user (app state shared by Home,
/// Favorites, Details and Profile).
///
/// Cycle: the UI adds a [PlacesEvent] → the handler talks to the
/// [PlacesRepository] → the repository's **live stream** reports the new
/// list → `emit` publishes a new [PlacesState] → `BlocBuilder`s rebuild.
/// The list is never edited in place, and the bloc never assumes a write
/// "worked": it shows what the repository says is stored, so a change from
/// another device appears the same way as the user's own.
///
/// One instance per uid: it is created with the user in `UserScope`, so
/// switching accounts drops this state and one user's catalog can never
/// leak to the next.
class PlacesBloc extends Bloc<PlacesEvent, PlacesState> {
  PlacesBloc({
    required this.uid,
    required PlacesRepository repository,
    required AnalyticsService analytics,
    required CrashReporter crashReporter,
  }) : _repository = repository,
       _analytics = analytics,
       _crashReporter = crashReporter,
       super(const PlacesState()) {
    on<PlacesLoadRequested>(_onLoad);
    on<_PlacesArrived>(_onArrived);
    on<_PlacesStreamFailed>(_onStreamFailed);
    on<PlaceCreated>(_onCreated);
    on<PlaceUpdated>(_onUpdated);
    on<PlaceDeleted>(_onDeleted);
    on<PlaceFavoriteToggled>(_onFavoriteToggled);
    on<PlaceOpened>(_onOpened);
  }

  final String uid;
  final PlacesRepository _repository;
  final AnalyticsService _analytics;
  final CrashReporter _crashReporter;

  StreamSubscription<List<Place>>? _subscription;

  /// (Re)subscribes to the catalog. Sent at start and by "Retry".
  Future<void> _onLoad(
    PlacesLoadRequested event,
    Emitter<PlacesState> emit,
  ) async {
    emit(state.copyWith(status: PlacesStatus.loading, clearError: true));
    // Not awaited: the old stream is simply dropped (nothing depends on the
    // moment its cancellation completes).
    unawaited(_subscription?.cancel());
    _subscription = _repository
        .watchPlaces(uid)
        .listen(
          (List<Place> places) => add(_PlacesArrived(places)),
          onError: (Object error, StackTrace stack) =>
              add(_PlacesStreamFailed(error, stack)),
        );
  }

  void _onArrived(_PlacesArrived event, Emitter<PlacesState> emit) {
    emit(
      state.copyWith(
        status: PlacesStatus.loaded,
        places: event.places,
        // A fresh list also ends an earlier "could not save" notice.
        clearError: true,
      ),
    );
  }

  Future<void> _onStreamFailed(
    _PlacesStreamFailed event,
    Emitter<PlacesState> emit,
  ) async {
    await _crashReporter.recordError(
      event.error,
      event.stack,
      reason: 'Watch places',
    );
    emit(
      state.copyWith(
        status: PlacesStatus.failure,
        errorMessage: event.error is PlacesFailure
            ? (event.error as PlacesFailure).message
            : AppStrings.placesLoadError,
      ),
    );
  }

  Future<void> _onCreated(PlaceCreated event, Emitter<PlacesState> emit) =>
      _save(emit, event.place);

  Future<void> _onUpdated(PlaceUpdated event, Emitter<PlacesState> emit) =>
      _save(emit, event.place);

  Future<void> _onFavoriteToggled(
    PlaceFavoriteToggled event,
    Emitter<PlacesState> emit,
  ) async {
    final Place? place = state.byId(event.placeId);
    if (place == null) return;
    final Place toggled = place.copyWith(isFavorite: !place.isFavorite);
    if (await _save(emit, toggled)) {
      _analytics.logPlaceFavoriteToggled(
        placeId: toggled.id,
        isFavorite: toggled.isFavorite,
      );
    }
  }

  Future<void> _onDeleted(PlaceDeleted event, Emitter<PlacesState> emit) async {
    emit(state.copyWith(clearError: true));
    try {
      await _repository.deletePlace(uid, event.placeId);
      // No emit: the live stream delivers the shorter list.
    } catch (error, stack) {
      await _failSave(emit, error, stack);
    }
  }

  void _onOpened(PlaceOpened event, Emitter<PlacesState> emit) {
    final Place? place = state.byId(event.placeId);
    if (place == null) return;
    _analytics.logPlaceOpened(placeId: place.id, category: place.category.name);
  }

  /// Writes [place]; the screen updates when the stream reports it.
  /// Returns whether the write was accepted.
  Future<bool> _save(Emitter<PlacesState> emit, Place place) async {
    emit(state.copyWith(clearError: true));
    try {
      await _repository.savePlace(uid, place);
      return true;
    } catch (error, stack) {
      await _failSave(emit, error, stack);
      return false;
    }
  }

  Future<void> _failSave(
    Emitter<PlacesState> emit,
    Object error,
    StackTrace stack,
  ) async {
    await _crashReporter.recordError(error, stack, reason: 'Save place');
    emit(
      state.copyWith(
        errorMessage: error is PlacesFailure
            ? error.message
            : AppStrings.placesSaveError,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
