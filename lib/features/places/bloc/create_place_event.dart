part of 'create_place_bloc.dart';

sealed class CreatePlaceEvent extends Equatable {
  const CreatePlaceEvent();

  @override
  List<Object?> get props => const [];
}

/// Save a new place. [draft] comes from the form: its `photos` may include
/// local files that still have to be uploaded; its `id` is ignored (the bloc
/// allocates the real one first, because photos are stored under it).
final class CreatePlaceSubmitted extends CreatePlaceEvent {
  const CreatePlaceSubmitted(this.draft);

  final Place draft;

  @override
  List<Object?> get props => [draft];
}

/// Forget the last result (a form was opened).
final class CreatePlaceReset extends CreatePlaceEvent {
  const CreatePlaceReset();
}
