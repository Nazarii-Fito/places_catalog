/// Where a photo's bytes live. It decides how the picture is displayed and
/// whether it still has to be uploaded.
enum PhotoKind {
  /// Bundled demo picture (the seeded catalog). Never uploaded or deleted.
  asset,

  /// A file picked on this device that has not reached cloud storage yet.
  /// It exists only inside the form; it is never written to Firestore.
  local,

  /// Uploaded to cloud storage; [PlacePhoto.location] is its public URL.
  remote,
}

/// A photo attached to a place.
///
/// One class for all three origins ([PhotoKind]) so the UI has a single type
/// to display (`PlaceImageView`) and the form can mix saved and new photos.
/// Only [PhotoKind.remote] photos carry cloud metadata.
class PlacePhoto {
  const PlacePhoto._({
    required this.kind,
    required this.location,
    required this.fileSizeBytes,
    this.storagePath,
    this.contentType,
    this.uploadedAt,
  });

  /// A bundled demo picture.
  const PlacePhoto.asset(String assetPath, {int fileSizeBytes = 0})
    : this._(
        kind: PhotoKind.asset,
        location: assetPath,
        fileSizeBytes: fileSizeBytes,
      );

  /// A device file that is waiting to be uploaded.
  const PlacePhoto.local(
    String filePath, {
    required int fileSizeBytes,
    String? contentType,
  }) : this._(
         kind: PhotoKind.local,
         location: filePath,
         fileSizeBytes: fileSizeBytes,
         contentType: contentType,
       );

  /// A file already in cloud storage.
  const PlacePhoto.remote({
    required String url,
    required String storagePath,
    required int fileSizeBytes,
    required String contentType,
    required DateTime uploadedAt,
  }) : this._(
         kind: PhotoKind.remote,
         location: url,
         fileSizeBytes: fileSizeBytes,
         storagePath: storagePath,
         contentType: contentType,
         uploadedAt: uploadedAt,
       );

  /// Reads the map written by [toJson]. Also accepts the Lab 5 format
  /// (`imageAsset` + `fileSizeBytes`) so saved local catalogs keep working.
  factory PlacePhoto.fromJson(Map<String, Object?> json) {
    final String? legacyAsset = json['imageAsset'] as String?;
    if (legacyAsset != null) {
      return PlacePhoto.asset(
        legacyAsset,
        fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      );
    }
    final PhotoKind kind = PhotoKind.values.byName(json['kind'] as String);
    final int size = (json['fileSizeBytes'] as num?)?.toInt() ?? 0;
    switch (kind) {
      case PhotoKind.asset:
        return PlacePhoto.asset(
          json['location'] as String,
          fileSizeBytes: size,
        );
      case PhotoKind.local:
        return PlacePhoto.local(
          json['location'] as String,
          fileSizeBytes: size,
          contentType: json['contentType'] as String?,
        );
      case PhotoKind.remote:
        return PlacePhoto.remote(
          url: json['location'] as String,
          storagePath: json['storagePath'] as String,
          fileSizeBytes: size,
          contentType: json['contentType'] as String,
          uploadedAt: DateTime.parse(json['uploadedAt'] as String),
        );
    }
  }

  final PhotoKind kind;

  /// Asset path, local file path or public URL, depending on [kind].
  final String location;
  final int fileSizeBytes;

  /// Object path inside the bucket (`users/<uid>/<placeId>/<file>`);
  /// `null` unless the photo is remote. Needed to delete the file later.
  final String? storagePath;
  final String? contentType;
  final DateTime? uploadedAt;

  bool get isRemote => kind == PhotoKind.remote;
  bool get isLocal => kind == PhotoKind.local;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'location': location,
    'fileSizeBytes': fileSizeBytes,
    'storagePath': storagePath,
    'contentType': contentType,
    'uploadedAt': uploadedAt?.toIso8601String(),
  };

  /// Two photos are the same when they point at the same bytes.
  @override
  bool operator ==(Object other) =>
      other is PlacePhoto && other.kind == kind && other.location == location;

  @override
  int get hashCode => Object.hash(kind, location);
}
