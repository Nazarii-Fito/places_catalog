import '../models/place.dart';

/// Where the catalog of one user lives.
///
/// An interface (not a concrete class) so the BLoC depends only on *what*
/// is stored, never on *how*: the app uses a JSON file, tests and the
/// screenshot mode use memory. The uid is a parameter, not a constructor
/// argument, because the repository is created before anybody signs in.
abstract interface class PlacesRepository {
  /// Every place of [uid]; seeds the demo catalog on the first run.
  Future<List<Place>> loadPlaces(String uid);

  /// Inserts a new place or replaces the one with the same id.
  Future<void> savePlace(String uid, Place place);

  Future<void> deletePlace(String uid, String placeId);
}
