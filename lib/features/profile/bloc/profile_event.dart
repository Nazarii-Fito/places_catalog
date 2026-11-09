part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => const [];
}

/// Subscribe to `userChanges()` (sent once when the bloc is created).
final class ProfileStarted extends ProfileEvent {
  const ProfileStarted();
}

/// Save the edited name and/or photo. `null` fields stay as they are.
final class ProfileUpdated extends ProfileEvent {
  const ProfileUpdated({
    this.displayName,
    this.photoUrl,
    this.photoSource = 'unchanged',
  });

  final String? displayName;
  final String? photoUrl;

  /// For Analytics only: `preset`, `custom` or `unchanged`.
  final String photoSource;

  @override
  List<Object?> get props => [displayName, photoUrl, photoSource];
}

final class ProfileGoogleLinkRequested extends ProfileEvent {
  const ProfileGoogleLinkRequested();
}

/// A screen has shown the error (or is being opened): forget it.
final class ProfileErrorDismissed extends ProfileEvent {
  const ProfileErrorDismissed();
}
