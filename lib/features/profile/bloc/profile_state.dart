part of 'profile_bloc.dart';

/// `saveFailure` and `linkFailure` are separate so that a failed Google
/// link never shows up as an error on Edit Profile (and vice versa).
enum ProfileStatus { loading, idle, saving, linking, saveFailure, linkFailure }

final class ProfileState extends Equatable {
  const ProfileState({
    this.user,
    this.status = ProfileStatus.loading,
    this.message,
  });

  final AppUser? user;
  final ProfileStatus status;
  final String? message;

  ProfileState copyWith({
    AppUser? user,
    ProfileStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      status: status ?? this.status,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [user, status, message];
}
