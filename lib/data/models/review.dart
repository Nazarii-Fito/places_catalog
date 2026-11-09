/// Multi-criteria review of a visit.
///
/// Only [overallRating] is required; the detailed ratings are nullable
/// (`double?`) because the user may skip them — Dart null safety forces
/// every reader to handle that case explicitly.
class Review {
  const Review({
    required this.overallRating,
    this.foodRating,
    this.serviceRating,
    this.atmosphereRating,
    this.textNote = '',
    this.tags = const [],
    this.updatedAt,
  }) : assert(overallRating >= 1 && overallRating <= 5);

  /// Reads the map written by [toJson]. Hand-written (no code generation)
  /// so the whole serialisation is visible in the report.
  factory Review.fromJson(Map<String, Object?> json) {
    final String? updated = json['updatedAt'] as String?;
    return Review(
      overallRating: (json['overallRating'] as num).toDouble(),
      foodRating: (json['foodRating'] as num?)?.toDouble(),
      serviceRating: (json['serviceRating'] as num?)?.toDouble(),
      atmosphereRating: (json['atmosphereRating'] as num?)?.toDouble(),
      textNote: json['textNote'] as String? ?? '',
      tags: [
        ...(json['tags'] as List<Object?>? ?? const <Object?>[]).cast<String>(),
      ],
      updatedAt: updated == null ? null : DateTime.parse(updated),
    );
  }

  final double overallRating;
  final double? foodRating;
  final double? serviceRating;
  final double? atmosphereRating;
  final String textNote;
  final List<String> tags;

  /// When the note was last edited; `null` for imported records.
  final DateTime? updatedAt;

  /// Plain JSON map; dates are ISO-8601 strings.
  Map<String, Object?> toJson() => {
    'overallRating': overallRating,
    'foodRating': foodRating,
    'serviceRating': serviceRating,
    'atmosphereRating': atmosphereRating,
    'textNote': textNote,
    'tags': tags,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  /// Returns a copy with the given fields replaced; `null` keeps the value.
  Review copyWith({
    double? overallRating,
    double? foodRating,
    double? serviceRating,
    double? atmosphereRating,
    String? textNote,
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return Review(
      overallRating: overallRating ?? this.overallRating,
      foodRating: foodRating ?? this.foodRating,
      serviceRating: serviceRating ?? this.serviceRating,
      atmosphereRating: atmosphereRating ?? this.atmosphereRating,
      textNote: textNote ?? this.textNote,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
