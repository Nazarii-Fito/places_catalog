/// A photo attached to a place.
class PlacePhoto {
  const PlacePhoto({required this.imageAsset, required this.fileSizeBytes});

  /// Reads the map written by [toJson]; throws [FormatException] otherwise.
  factory PlacePhoto.fromJson(Map<String, Object?> json) {
    return PlacePhoto(
      imageAsset: json['imageAsset'] as String,
      fileSizeBytes: (json['fileSizeBytes'] as num).toInt(),
    );
  }

  final String imageAsset;
  final int fileSizeBytes;

  Map<String, Object?> toJson() => {
    'imageAsset': imageAsset,
    'fileSizeBytes': fileSizeBytes,
  };
}
