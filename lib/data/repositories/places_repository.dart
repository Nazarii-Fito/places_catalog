import '../models/place.dart';

/// One page of the catalog plus the position to continue from.
class PlacesPage {
  const PlacesPage({required this.places, this.cursor});

  final List<Place> places;

  /// Opaque position of the last item; pass it back to `loadPage` for the
  /// next page. `null` means there is nothing more to load.
  final Object? cursor;

  bool get hasMore => cursor != null;
}

/// Where the catalog of one user lives.
///
/// An interface (not a concrete class) so the BLoC depends only on *what*
/// is stored, never on *how*: the app uses Cloud Firestore (or a JSON file
/// with `PLACES_BACKEND=local`), tests and the screenshot mode use memory.
/// The uid is a parameter, not a constructor argument, because the
/// repository is created before anybody signs in.
abstract interface class PlacesRepository {
  /// The whole catalog of [uid], re-emitted whenever it changes — also when
  /// the change comes from another device. Seeds the demo catalog on the
  /// first run. Sorted by visit date (newest first).
  Stream<List<Place>> watchPlaces(String uid);

  /// A single read of the whole catalog (same order as [watchPlaces]).
  Future<List<Place>> loadPlaces(String uid);

  /// One page of [perPage] places, for lists too long to load at once.
  /// Pass the previous page's `cursor` to continue.
  Future<PlacesPage> loadPage(String uid, {int perPage = 20, Object? cursor});

  /// A new unique id for a place, available before the place is saved, so
  /// photos can be uploaded under `<placeId>/` first.
  String newPlaceId(String uid);

  /// Inserts a new place or replaces the one with the same id.
  Future<void> savePlace(String uid, Place place);

  Future<void> deletePlace(String uid, String placeId);
}
