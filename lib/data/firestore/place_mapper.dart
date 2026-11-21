import '../models/place.dart';
import '../models/place_category.dart';
import '../models/place_photo.dart';
import '../models/review.dart';

/// Converts a [Place] to and from the plain map stored in a Firestore
/// document (`users/{uid}/places/{placeId}`).
///
/// The maps contain only Dart types (`DateTime`, `num`, `List`, `Map`): the
/// Firestore store turns `DateTime` into `Timestamp` at the very edge, so
/// this mapper (and the repository logic above it) can be tested without
/// the SDK.
///
/// * `review` is embedded in the place document: it is 1:1 with the place and
///   always read together with it.
/// * `photos` is an array (max 5), not a sub-collection: one read returns the
///   whole place and the small limit keeps the document tiny.
/// * A photo that is still a local file never reaches Firestore: files are
///   uploaded first, only their metadata is stored.
abstract final class PlaceMapper {
  static Map<String, Object?> toMap(Place place) {
    final Review? review = place.review;
    return {
      'name': place.name,
      'category': place.category.name,
      'subtitle': place.subtitle,
      'address': place.address,
      'latitude': place.latitude,
      'longitude': place.longitude,
      'visitDate': place.visitDate,
      'isFavorite': place.isFavorite,
      'cover': _photoToMap(place.coverImage),
      'review': review == null ? null : _reviewToMap(review),
      'photos': [for (final PlacePhoto p in place.photos) _photoToMap(p)],
      // Only an existing record carries its creation time; for a new one the
      // store stamps it with the server time.
      if (place.createdAt != null) 'createdAt': place.createdAt,
    };
  }

  /// Builds a [Place] from document [data]. Throws if the data is damaged
  /// (missing field, unknown category) so the caller can report it.
  static Place fromMap(String id, Map<String, Object?> data) {
    final Object? review = data['review'];
    return Place(
      id: id,
      name: data['name']! as String,
      category: PlaceCategory.values.byName(data['category']! as String),
      subtitle: data['subtitle'] as String? ?? '',
      address: data['address'] as String? ?? '',
      visitDate: data['visitDate']! as DateTime,
      coverImage: _photoFromMap(_map(data['cover'])),
      createdAt: data['createdAt'] as DateTime?,
      review: review == null ? null : _reviewFromMap(_map(review)),
      isFavorite: data['isFavorite'] as bool? ?? false,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      photos: [
        for (final Object? p in data['photos'] as List<Object?>? ?? const [])
          _photoFromMap(_map(p)),
      ],
    );
  }

  static Map<String, Object?> _map(Object? raw) =>
      (raw! as Map<Object?, Object?>).cast<String, Object?>();

  static Map<String, Object?> _photoToMap(PlacePhoto photo) {
    if (photo.isLocal) {
      throw StateError('A local photo must be uploaded before it is saved.');
    }
    return {
      'kind': photo.kind.name,
      'url': photo.location,
      'storagePath': photo.storagePath,
      'sizeBytes': photo.fileSizeBytes,
      'contentType': photo.contentType,
      'uploadedAt': photo.uploadedAt,
    };
  }

  static PlacePhoto _photoFromMap(Map<String, Object?> map) {
    final int size = (map['sizeBytes'] as num?)?.toInt() ?? 0;
    final String url = map['url']! as String;
    switch (PhotoKind.values.byName(map['kind']! as String)) {
      case PhotoKind.asset:
        return PlacePhoto.asset(url, fileSizeBytes: size);
      case PhotoKind.remote:
        return PlacePhoto.remote(
          url: url,
          storagePath: map['storagePath']! as String,
          fileSizeBytes: size,
          contentType: map['contentType']! as String,
          uploadedAt: map['uploadedAt']! as DateTime,
        );
      case PhotoKind.local:
        throw StateError('A local photo cannot be stored.');
    }
  }

  static Map<String, Object?> _reviewToMap(Review r) => {
    'overallRating': r.overallRating,
    'foodRating': r.foodRating,
    'serviceRating': r.serviceRating,
    'atmosphereRating': r.atmosphereRating,
    'textNote': r.textNote,
    'tags': r.tags,
    'updatedAt': r.updatedAt,
  };

  static Review _reviewFromMap(Map<String, Object?> m) => Review(
    overallRating: (m['overallRating']! as num).toDouble(),
    foodRating: (m['foodRating'] as num?)?.toDouble(),
    serviceRating: (m['serviceRating'] as num?)?.toDouble(),
    atmosphereRating: (m['atmosphereRating'] as num?)?.toDouble(),
    textNote: m['textNote'] as String? ?? '',
    tags: [
      ...(m['tags'] as List<Object?>? ?? const <Object?>[]).cast<String>(),
    ],
    updatedAt: m['updatedAt'] as DateTime?,
  );
}
