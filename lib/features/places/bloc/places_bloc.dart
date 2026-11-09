// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/models/place.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/crash_reporter.dart';

part 'places_event.dart';
part 'places_state.dart';

/// Owns the catalog of one signed-in user (app state shared by Home,
/// Favorites, Details and Profile).
///
/// Cycle: the UI adds an [PlacesEvent] → the handler talks to the
/// [PlacesRepository] (disk) → `emit` publishes a *new* [PlacesState] →
/// `BlocBuilder`s rebuild. The list is never mutated in place, so
/// Equatable can tell that something changed.
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
    on<PlaceCreated>(_onCreated);
    on<PlaceUpdated>(_onUpdated);
    on<PlaceDeleted>(_onDeleted);
    on<PlaceFavoriteToggled>(_onFavoriteToggled);
    on<PlaceOpened>(_onOpened);
  }

  final String uid;
  final PlacesRepository _repository;

  /// Lets tests flip a fake repository between calls.
  @visibleForTesting
  PlacesRepository get repositoryForTest => _repository;
  final AnalyticsService _analytics;
  final CrashReporter _crashReporter;

  Future<void> _onLoad(
    PlacesLoadRequested event,
    Emitter<PlacesState> emit,
  ) async {
    emit(state.copyWith(status: PlacesStatus.loading, clearError: true));
    try {
      final List<Place> places = await _repository.loadPlaces(uid);
      emit(state.copyWith(status: PlacesStatus.loaded, places: places));
    } catch (error, stack) {
      await _crashReporter.recordError(error, stack, reason: 'Load places');
      emit(
        state.copyWith(
          status: PlacesStatus.failure,
          errorMessage: AppStrings.placesLoadError,
        ),
      );
    }
  }

  Future<void> _onCreated(PlaceCreated event, Emitter<PlacesState> emit) =>
      _change(emit, event.place, [...state.places, event.place]);

  Future<void> _onUpdated(PlaceUpdated event, Emitter<PlacesState> emit) =>
      _change(emit, event.place, [
        for (final Place p in state.places)
          p.id == event.place.id ? event.place : p,
      ]);

  Future<void> _onFavoriteToggled(
    PlaceFavoriteToggled event,
    Emitter<PlacesState> emit,
  ) async {
    final Place? place = state.byId(event.placeId);
    if (place == null) return;
    final Place toggled = place.copyWith(isFavorite: !place.isFavorite);
    await _change(emit, toggled, [
      for (final Place p in state.places) p.id == toggled.id ? toggled : p,
    ]);
    _analytics.logPlaceFavoriteToggled(
      placeId: toggled.id,
      isFavorite: toggled.isFavorite,
    );
  }

  Future<void> _onDeleted(PlaceDeleted event, Emitter<PlacesState> emit) async {
    emit(state.copyWith(clearError: true));
    try {
      await _repository.deletePlace(uid, event.placeId);
      emit(
        state.copyWith(
          places: [
            for (final Place p in state.places)
              if (p.id != event.placeId) p,
          ],
        ),
      );
    } catch (error, stack) {
      await _failSave(emit, error, stack);
    }
  }

  void _onOpened(PlaceOpened event, Emitter<PlacesState> emit) {
    final Place? place = state.byId(event.placeId);
    if (place == null) return;
    _analytics.logPlaceOpened(placeId: place.id, category: place.category.name);
  }

  /// Saves [place] first and only then publishes [next]: the screen never
  /// shows a change that is not on disk.
  Future<void> _change(
    Emitter<PlacesState> emit,
    Place place,
    List<Place> next,
  ) async {
    emit(state.copyWith(clearError: true));
    try {
      await _repository.savePlace(uid, place);
      emit(state.copyWith(places: next));
    } catch (error, stack) {
      await _failSave(emit, error, stack);
    }
  }

  Future<void> _failSave(
    Emitter<PlacesState> emit,
    Object error,
    StackTrace stack,
  ) async {
    await _crashReporter.recordError(error, stack, reason: 'Save place');
    emit(state.copyWith(errorMessage: AppStrings.placesSaveError));
  }
}
