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

  final double overallRating;
  final double? foodRating;
  final double? serviceRating;
  final double? atmosphereRating;
  final String textNote;
  final List<String> tags;

  /// When the note was last edited; `null` for imported records.
  final DateTime? updatedAt;
}
