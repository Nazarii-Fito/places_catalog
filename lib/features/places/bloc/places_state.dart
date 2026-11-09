part of 'places_bloc.dart';

enum PlacesStatus { initial, loading, loaded, failure }

/// Immutable snapshot of the catalog for the UI.
///
/// [errorMessage] has two meanings, told apart by [status]: with `failure`
/// the list could not be loaded (full-screen error + Retry); with `loaded`
/// a later change could not be saved (the list is intact, an alert is
/// shown once).
final class PlacesState extends Equatable {
  const PlacesState({
    this.status = PlacesStatus.initial,
    this.places = const [],
    this.errorMessage,
  });

  final PlacesStatus status;
  final List<Place> places;
  final String? errorMessage;

  /// The place with [id], or `null` (e.g. right after it was deleted).
  Place? byId(String id) {
    for (final Place place in places) {
      if (place.id == id) return place;
    }
    return null;
  }

  PlacesState copyWith({
    PlacesStatus? status,
    List<Place>? places,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlacesState(
      status: status ?? this.status,
      places: places ?? this.places,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, places, errorMessage];
}
