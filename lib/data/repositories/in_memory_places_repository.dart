import 'dart:async';

import '../mock/mock_places.dart';
import '../models/place.dart';
import 'places_ordering.dart';
import 'reloading_stream.dart';
import 'places_repository.dart';

/// Keeps catalogs in memory: used by tests and the `FAKE_AUTH` screenshot
/// mode, where touching the disk or the network would make runs depend on
/// earlier runs.
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
  final StreamController<String> _changes =
      StreamController<String>.broadcast();
  int _nextId = 0;

  List<Place> _list(String uid) =>
      _byUser.putIfAbsent(uid, () => List.of(_seed));

  @override
  Stream<List<Place>> watchPlaces(String uid) => reloadingStream(
    load: () => loadPlaces(uid),
    changes: _changes.stream.where((String changed) => changed == uid),
  );

  @override
  Future<List<Place>> loadPlaces(String uid) async {
    await Future<void>.delayed(delay);
    if (failLoad) throw StateError('Simulated load failure');
    return sortPlaces(_list(uid));
  }

  @override
  Future<PlacesPage> loadPage(
    String uid, {
    int perPage = 20,
    Object? cursor,
  }) async => pageOf(await loadPlaces(uid), perPage: perPage, cursor: cursor);

  @override
  String newPlaceId(String uid) => 'mem-${_nextId++}';

  @override
  Future<void> savePlace(String uid, Place place) async {
    final List<Place> list = _list(uid);
    final int index = list.indexWhere((Place p) => p.id == place.id);
    if (index == -1) {
      list.add(place);
    } else {
      list[index] = place;
    }
    _changes.add(uid);
  }

  @override
  Future<void> deletePlace(String uid, String placeId) async {
    _list(uid).removeWhere((Place p) => p.id == placeId);
    _changes.add(uid);
  }
}
