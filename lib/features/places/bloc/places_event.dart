part of 'places_bloc.dart';

/// Everything that can happen to the catalog. Each event is a plain
/// immutable message from the UI (or app code) to [PlacesBloc]: the UI
/// never edits the list itself, it only *describes what the user did*.
sealed class PlacesEvent extends Equatable {
  const PlacesEvent();

  @override
  List<Object?> get props => const [];
}

/// Load the catalog from the repository (first start and "Retry").
final class PlacesLoadRequested extends PlacesEvent {
  const PlacesLoadRequested();
}

/// A new place from the form.
final class PlaceCreated extends PlacesEvent {
  const PlaceCreated(this.place);

  final Place place;

  @override
  List<Object?> get props => [place];
}

/// The edited copy of an existing place (form, notes, tags).
final class PlaceUpdated extends PlacesEvent {
  const PlaceUpdated(this.place);

  final Place place;

  @override
  List<Object?> get props => [place];
}

final class PlaceDeleted extends PlacesEvent {
  const PlaceDeleted(this.placeId);

  final String placeId;

  @override
  List<Object?> get props => [placeId];
}

final class PlaceFavoriteToggled extends PlacesEvent {
  const PlaceFavoriteToggled(this.placeId);

  final String placeId;

  @override
  List<Object?> get props => [placeId];
}

/// A card was opened. Changes no data; it exists so the analytics call
/// lives in the bloc and not in a widget.
final class PlaceOpened extends PlacesEvent {
  const PlaceOpened(this.placeId);

  final String placeId;

  @override
  List<Object?> get props => [placeId];
}
