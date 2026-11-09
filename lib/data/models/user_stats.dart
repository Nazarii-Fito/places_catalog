/// Activity counters shown on the profile screen (computed from the
/// catalog by `ProfileScreen`).
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
