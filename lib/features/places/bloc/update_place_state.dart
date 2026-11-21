part of 'update_place_bloc.dart';

sealed class UpdatePlaceState extends Equatable {
  const UpdatePlaceState();

  @override
  List<Object?> get props => const [];
}

final class UpdatePlaceIdle extends UpdatePlaceState {
  const UpdatePlaceIdle();
}

final class PlaceUpdatingState extends UpdatePlaceState {
  const PlaceUpdatingState({
    this.uploaded = 0,
    this.total = 0,
    this.origin = UpdateOrigin.form,
  });

  final int uploaded;
  final int total;
  final UpdateOrigin origin;

  @override
  List<Object?> get props => [uploaded, total, origin];
}

final class PlaceUpdateErrorState extends UpdatePlaceState {
  const PlaceUpdateErrorState({
    required this.message,
    required this.retryable,
    required this.origin,
  });

  final String message;
  final bool retryable;
  final UpdateOrigin origin;

  @override
  List<Object?> get props => [message, retryable, origin];
}

final class PlaceUpdateSuccessState extends UpdatePlaceState {
  const PlaceUpdateSuccessState(this.place, {required this.origin});

  final Place place;
  final UpdateOrigin origin;

  @override
  List<Object?> get props => [place, origin];
}
