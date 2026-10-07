import 'place_category.dart';
import 'place_photo.dart';
import 'review.dart';

/// A visited venue — the central entity of the catalog.
///
/// Immutable: every field is `final`, and changes (e.g. toggling favourite)
/// produce a new instance through [copyWith].
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.subtitle,
    required this.address,
    required this.visitDate,
    required this.coverImage,
    this.review,
    this.isFavorite = false,
    this.latitude,
    this.longitude,
    this.photos = const [],
  });

  final String id;
  final String name;
  final PlaceCategory category;

  /// Cuisine / sub-type shown under the name, e.g. "Museum & Art".
  final String subtitle;
  final String address;
  final DateTime visitDate;
  final String coverImage;
  final Review? review;
  final bool isFavorite;
  final double? latitude;
  final double? longitude;
  final List<PlacePhoto> photos;

  int get photosCount => photos.length;

  /// Overall rating, or 0 when the place has not been reviewed yet.
  double get rating => review?.overallRating ?? 0;

  Place copyWith({bool? isFavorite}) {
    return Place(
      id: id,
      name: name,
      category: category,
      subtitle: subtitle,
      address: address,
      visitDate: visitDate,
      coverImage: coverImage,
      review: review,
      isFavorite: isFavorite ?? this.isFavorite,
      latitude: latitude,
      longitude: longitude,
      photos: photos,
    );
  }
}
