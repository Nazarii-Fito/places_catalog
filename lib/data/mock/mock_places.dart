import '../../core/constants/app_assets.dart';
import '../models/place.dart';
import '../models/place_category.dart';
import '../models/place_photo.dart';
import '../models/review.dart';

/// Hardcoded catalog shown on Home (texts and photos come from Figma).
///
/// `final`, not `const`, because [DateTime] has no const constructor.
final List<Place> mockPlaces = [
  Place(
    id: 'daily-grind',
    name: 'The Daily Grind',
    category: PlaceCategory.cafe,
    subtitle: 'Cafe',
    address: '424 Broome St, SoHo, Manhattan',
    visitDate: DateTime(2023, 10, 14),
    coverImage: AppAssets.placeDailyGrind,
    isFavorite: true,
    latitude: 40.7219,
    longitude: -73.9995,
    review: const Review(
      overallRating: 5.0,
      foodRating: 5.0,
      serviceRating: 4.8,
      atmosphereRating: 5.0,
      textNote:
          'Incredible warm lighting and exposed brick interior. The Ethiopian '
          'pour-over was exceptional with bright floral notes.',
      tags: ['#Espresso', '#Pastries', '#QuietWork', '#NaturalLight'],
    ),
    photos: const [
      PlacePhoto(imageAsset: AppAssets.placeDailyGrind, fileSizeBytes: 13997),
    ],
  ),
  Place(
    id: 'osteria-del-sole',
    name: 'Osteria Del Sole',
    category: PlaceCategory.restaurant,
    subtitle: 'Restaurant',
    address: '58 Mulberry St, Little Italy, Manhattan',
    visitDate: DateTime(2023, 9, 29),
    coverImage: AppAssets.placeOsteriaDelSole,
    latitude: 40.7155,
    longitude: -73.9989,
    review: const Review(
      overallRating: 4.8,
      foodRating: 5.0,
      serviceRating: 4.5,
      tags: ['#Pasta', '#DateNight'],
    ),
  ),
  Place(
    id: 'moma-modern-cafe',
    name: 'MOMA Modern Cafe',
    category: PlaceCategory.museum,
    subtitle: 'Museum & Art',
    address: '11 W 53rd St, Midtown, Manhattan',
    visitDate: DateTime(2023, 9, 12),
    coverImage: AppAssets.placeMomaModernCafe,
    isFavorite: true,
    latitude: 40.7614,
    longitude: -73.9776,
    review: const Review(
      overallRating: 4.9,
      atmosphereRating: 5.0,
      tags: ['#Art', '#Coffee'],
    ),
  ),
  Place(
    id: 'kurobuta-ramen',
    name: 'Kurobuta Ramen',
    category: PlaceCategory.restaurant,
    subtitle: 'Restaurant',
    address: '177 Ludlow St, Lower East Side, Manhattan',
    visitDate: DateTime(2023, 8, 24),
    coverImage: AppAssets.placeKurobutaRamen,
    latitude: 40.7213,
    longitude: -73.9877,
    review: const Review(
      overallRating: 4.7,
      foodRating: 4.9,
      tags: ['#Ramen', '#LateNight'],
    ),
  ),
];
