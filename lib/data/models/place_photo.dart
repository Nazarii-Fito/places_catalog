/// A photo attached to a place.
class PlacePhoto {
  const PlacePhoto({required this.imageAsset, required this.fileSizeBytes});

  final String imageAsset;
  final int fileSizeBytes;
}
