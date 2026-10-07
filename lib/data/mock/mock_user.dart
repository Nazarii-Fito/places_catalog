import '../../core/constants/app_assets.dart';
import '../models/user.dart';

/// Hardcoded profile data (Lab 3 has no backend). Values match Figma.
final User mockUser = User(
  fullName: 'Nazarii Fito',
  email: 'nazarii.fito@gmail.com',
  avatarAsset: AppAssets.avatarNazariiFito,
  registrationDate: DateTime(2023, 3, 1),
  stats: const UserStats(
    totalVisitedPlaces: 42,
    cafes: 28,
    dining: 10,
    museums: 4,
    favorites: 18,
  ),
);
