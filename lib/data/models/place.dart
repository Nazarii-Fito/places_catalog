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

  /// Large photo for Place Details: the first attached photo, or the cover.
  String get heroImage => photos.isEmpty ? coverImage : photos.first.imageAsset;

  /// Overall rating, or 0 when the place has not been reviewed yet.
  double get rating => review?.overallRating ?? 0;

  /// Returns a copy with the given fields replaced (immutable update).
  ///
  /// Every field is replaceable because the Edit Place form rebuilds the
  /// whole record; `null` arguments keep the current value.
  Place copyWith({
    String? name,
    PlaceCategory? category,
    String? subtitle,
    String? address,
    DateTime? visitDate,
    String? coverImage,
    Review? review,
    bool? isFavorite,
    double? latitude,
    double? longitude,
    List<PlacePhoto>? photos,
  }) {
    return Place(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      subtitle: subtitle ?? this.subtitle,
      address: address ?? this.address,
      visitDate: visitDate ?? this.visitDate,
      coverImage: coverImage ?? this.coverImage,
      review: review ?? this.review,
      isFavorite: isFavorite ?? this.isFavorite,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photos: photos ?? this.photos,
    );
  }
}
