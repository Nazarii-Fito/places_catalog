import '../models/place.dart';
import 'places_repository.dart';

/// The catalog order shared by every backend: newest visit first; places
/// visited the same day by creation time (newest first, unsaved-yet last in
/// time = newest), then by id so the order is fully stable.
List<Place> sortPlaces(Iterable<Place> places) {
  final List<Place> sorted = places.toList();
  sorted.sort((Place a, Place b) {
    final int byVisit = b.visitDate.compareTo(a.visitDate);
    if (byVisit != 0) return byVisit;
    // A record whose server time has not arrived yet counts as the newest.
    final DateTime ca =
        a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(1 << 50);
    final DateTime cb =
        b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(1 << 50);
    final int byCreated = cb.compareTo(ca);
    return byCreated != 0 ? byCreated : a.id.compareTo(b.id);
  });
  return sorted;
}

/// Pages an already sorted list; the cursor is the id of the last item.
PlacesPage pageOf(List<Place> sorted, {required int perPage, Object? cursor}) {
  final int start = cursor == null
      ? 0
      : sorted.indexWhere((Place p) => p.id == cursor) + 1;
  final List<Place> page = sorted.skip(start).take(perPage).toList();
  final bool more = start + page.length < sorted.length;
  return PlacesPage(places: page, cursor: more ? page.last.id : null);
}
