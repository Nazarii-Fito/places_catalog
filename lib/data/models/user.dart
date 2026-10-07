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
    required this.avatarAsset,
    required this.registrationDate,
    required this.stats,
  });

  final String fullName;
  final String email;
  final String avatarAsset;
  final DateTime registrationDate;
  final UserStats stats;

  int get totalVisitedPlaces => stats.totalVisitedPlaces;
}
