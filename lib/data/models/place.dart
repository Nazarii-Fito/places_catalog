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
    this.createdAt,
    this.review,
    this.isFavorite = false,
    this.latitude,
    this.longitude,
    this.photos = const [],
  });

  /// Reads the map written by [toJson]. The category is stored by `name`, so
  /// reordering the enum never corrupts saved data; an unknown name throws
  /// [ArgumentError], which the repository treats as a damaged file.
  factory Place.fromJson(Map<String, Object?> json) {
    final Object? review = json['review'];
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      category: PlaceCategory.values.byName(json['category'] as String),
      subtitle: json['subtitle'] as String,
      address: json['address'] as String,
      visitDate: DateTime.parse(json['visitDate'] as String),
      coverImage: _coverFromJson(json['coverImage']),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      review: review == null
          ? null
          : Review.fromJson((review as Map<Object?, Object?>).cast()),
      isFavorite: json['isFavorite'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      photos: [
        for (final Object? p in json['photos'] as List<Object?>? ?? const [])
          PlacePhoto.fromJson((p as Map<Object?, Object?>).cast()),
      ],
    );
  }

  /// Lab 5 files stored the cover as a bare asset path; newer ones as a map.
  static PlacePhoto _coverFromJson(Object? raw) => raw is String
      ? PlacePhoto.asset(raw)
      : PlacePhoto.fromJson((raw! as Map<Object?, Object?>).cast());

  final String id;
  final String name;
  final PlaceCategory category;

  /// Cuisine / sub-type shown under the name, e.g. "Museum & Art".
  final String subtitle;
  final String address;
  final DateTime visitDate;

  /// Thumbnail shown on cards; the first photo for user-created places.
  final PlacePhoto coverImage;

  /// When the record was first saved; `null` for old local records. Used as
  /// the tie-breaker when two places share a visit date.
  final DateTime? createdAt;
  final Review? review;
  final bool isFavorite;
  final double? latitude;
  final double? longitude;
  final List<PlacePhoto> photos;

  /// Plain JSON map shared by local storage and the Export Archive screen.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'subtitle': subtitle,
    'address': address,
    'visitDate': visitDate.toIso8601String(),
    'coverImage': coverImage.toJson(),
    'createdAt': createdAt?.toIso8601String(),
    'review': review?.toJson(),
    'isFavorite': isFavorite,
    'latitude': latitude,
    'longitude': longitude,
    'photos': [for (final PlacePhoto p in photos) p.toJson()],
  };

  int get photosCount => photos.length;

  /// Large photo for Place Details: the first attached photo, or the cover.
  PlacePhoto get heroImage => photos.isEmpty ? coverImage : photos.first;

  /// Overall rating, or 0 when the place has not been reviewed yet.
  double get rating => review?.overallRating ?? 0;

  /// Returns a copy with the given fields replaced (immutable update).
  ///
  /// Every field is replaceable because the Edit Place form rebuilds the
  /// whole record; `null` arguments keep the current value.
  Place copyWith({
    String? id,
    String? name,
    PlaceCategory? category,
    String? subtitle,
    String? address,
    DateTime? visitDate,
    PlacePhoto? coverImage,
    DateTime? createdAt,
    Review? review,
    bool? isFavorite,
    double? latitude,
    double? longitude,
    List<PlacePhoto>? photos,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subtitle: subtitle ?? this.subtitle,
      address: address ?? this.address,
      visitDate: visitDate ?? this.visitDate,
      coverImage: coverImage ?? this.coverImage,
      createdAt: createdAt ?? this.createdAt,
      review: review ?? this.review,
      isFavorite: isFavorite ?? this.isFavorite,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photos: photos ?? this.photos,
    );
  }
}
