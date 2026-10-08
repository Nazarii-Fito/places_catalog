/// Activity counters shown on the profile screen.
class UserStats {
  const UserStats({
    required this.totalVisitedPlaces,
    required this.cafes,
    required this.dining,
    required this.museums,
    required this.favorites,
  });

  final int totalVisitedPlaces;
  final int cafes;
  final int dining;
  final int museums;
  final int favorites;
}

/// The signed-in user.
class User {
  const User({
    required this.fullName,
    required this.email,
    this.avatarAsset,
    required this.registrationDate,
    required this.stats,
  });

  final String fullName;
  final String email;

  /// Bundled avatar image; `null` after the user removes the photo
  /// (the UI then shows initials).
  final String? avatarAsset;
  final DateTime registrationDate;
  final UserStats stats;

  int get totalVisitedPlaces => stats.totalVisitedPlaces;

  /// Initials for the avatar placeholder, e.g. "NF".
  String get initials => fullName
      .split(' ')
      .where((String part) => part.isNotEmpty)
      .take(2)
      .map((String part) => part[0].toUpperCase())
      .join();

  /// Returns a copy with edited profile fields. [removeAvatar] clears the
  /// photo, because a `null` [avatarAsset] already means "keep current".
  User copyWith({
    String? fullName,
    String? email,
    String? avatarAsset,
    bool removeAvatar = false,
  }) {
    return User(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarAsset: removeAvatar ? null : avatarAsset ?? this.avatarAsset,
      registrationDate: registrationDate,
      stats: stats,
    );
  }
}
