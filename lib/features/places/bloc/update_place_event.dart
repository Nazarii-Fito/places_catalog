part of 'update_place_bloc.dart';

/// Which screen started the update, so only that screen reports its result
/// (the Place form and the notes/tags editor on Details share the bloc).
enum UpdateOrigin { form, inline }

sealed class UpdatePlaceEvent extends Equatable {
  const UpdatePlaceEvent();

  @override
  List<Object?> get props => const [];
}

/// Save the edited place. [original] is what is stored now; [draft] is the
/// wanted result. Comparing them tells which photos are kept, new (local
/// files to upload) and removed (to delete from storage afterwards).
final class UpdatePlaceSubmitted extends UpdatePlaceEvent {
  const UpdatePlaceSubmitted({
    required this.original,
    required this.draft,
    this.origin = UpdateOrigin.form,
  });

  final Place original;
  final Place draft;
  final UpdateOrigin origin;

  @override
  List<Object?> get props => [original, draft, origin];
}

final class UpdatePlaceReset extends UpdatePlaceEvent {
  const UpdatePlaceReset();
}
