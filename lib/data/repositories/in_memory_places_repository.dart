import '../mock/mock_places.dart';
import '../models/place.dart';
import 'places_repository.dart';

/// Keeps catalogs in memory: used by tests and the `FAKE_AUTH` screenshot
/// mode, where touching the disk would make runs depend on earlier runs.
class InMemoryPlacesRepository implements PlacesRepository {
  /// [seed] is what a user sees on the first load (the Figma demo data by
  /// default). [delay] simulates a slow disk so loading states are visible;
  /// [failLoad] makes loading throw, to test the error state.
  InMemoryPlacesRepository({
    List<Place>? seed,
    this.delay = Duration.zero,
    this.failLoad = false,
  }) : _seed = seed ?? mockPlaces;

  final List<Place> _seed;
  final Duration delay;
  bool failLoad;
  final Map<String, List<Place>> _byUser = {};

  @override
  Future<List<Place>> loadPlaces(String uid) async {
    await Future<void>.delayed(delay);
    if (failLoad) throw StateError('Simulated load failure');
    return List.of(_byUser.putIfAbsent(uid, () => List.of(_seed)));
  }

  @override
  Future<void> savePlace(String uid, Place place) async {
    final List<Place> list = _byUser.putIfAbsent(uid, () => List.of(_seed));
    final int index = list.indexWhere((Place p) => p.id == place.id);
    if (index == -1) {
      list.add(place);
    } else {
      list[index] = place;
    }
  }

  @override
  Future<void> deletePlace(String uid, String placeId) async {
    _byUser
        .putIfAbsent(uid, () => List.of(_seed))
        .removeWhere((Place p) => p.id == placeId);
  }
}
