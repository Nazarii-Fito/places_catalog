part of 'create_place_bloc.dart';

sealed class CreatePlaceState extends Equatable {
  const CreatePlaceState();

  @override
  List<Object?> get props => const [];
}

final class CreatePlaceIdle extends CreatePlaceState {
  const CreatePlaceIdle();
}

/// Saving is in progress: [uploaded] of [total] photos are in storage.
/// The form disables Save and shows "Uploading 2 of 4".
final class PlaceCreatingState extends CreatePlaceState {
  const PlaceCreatingState({this.uploaded = 0, this.total = 0});

  final int uploaded;
  final int total;

  @override
  List<Object?> get props => [uploaded, total];
}

final class PlaceCreateErrorState extends CreatePlaceState {
  const PlaceCreateErrorState({required this.message, required this.retryable});

  final String message;

  /// The same request may work later (no network); false for "storage not
  /// configured" or a rejected file.
  final bool retryable;

  @override
  List<Object?> get props => [message, retryable];
}

final class PlaceCreateSuccessState extends CreatePlaceState {
  const PlaceCreateSuccessState(this.place);

  final Place place;

  @override
  List<Object?> get props => [place];
}
