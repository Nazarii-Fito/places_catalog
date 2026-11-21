import 'dart:async';

import '../repositories/reloading_stream.dart';
import 'places_document_store.dart';

/// [PlacesDocumentStore] kept in memory: a stand-in for Firestore in tests.
///
/// It behaves like the real thing where the repository cares: ordering by
/// `visitDate`, `createdAt`/`updatedAt` stamping, listeners that fire on
/// every change, and a once-only seed.
class InMemoryPlacesDocumentStore implements PlacesDocumentStore {
  InMemoryPlacesDocumentStore({this.failWith, this.hang = false});

  /// When set, every write throws it (simulates `permission-denied`…).
  Object? failWith;

  /// When `true`, writes never complete — like Firestore without a network.
  bool hang;

  final Map<String, Map<String, Map<String, Object?>>> _places = {};
  final Set<String> _seeded = {};
  final Map<String, StreamController<void>> _changes = {};
  int _nextId = 0;

  /// How many times a user was seeded (tests assert "only once").
  int seedCount = 0;

  StreamController<void> _controller(String uid) =>
      _changes.putIfAbsent(uid, StreamController<void>.broadcast);

  List<PlaceDoc> _sorted(String uid) {
    final List<PlaceDoc> docs = [
      for (final MapEntry<String, Map<String, Object?>> e
          in (_places[uid] ?? const <String, Map<String, Object?>>{}).entries)
        PlaceDoc(e.key, Map.of(e.value), cursor: e.key),
    ];
    // Like Firestore, a document without the ordered field sorts last.
    DateTime visit(PlaceDoc d) =>
        d.data['visitDate'] as DateTime? ??
        DateTime.fromMillisecondsSinceEpoch(0);
    docs.sort((PlaceDoc a, PlaceDoc b) {
      final int byVisit = visit(b).compareTo(visit(a));
      return byVisit != 0 ? byVisit : a.id.compareTo(b.id);
    });
    return docs;
  }

  @override
  String newId(String uid) => 'doc${_nextId++}';

  @override
  Stream<List<PlaceDoc>> watch(String uid) => reloadingStream(
    load: () async => _sorted(uid),
    changes: _controller(uid).stream,
  );

  @override
  Future<List<PlaceDoc>> fetchPage(
    String uid, {
    required int limit,
    Object? after,
  }) async {
    final List<PlaceDoc> all = _sorted(uid);
    final int start = after == null
        ? 0
        : all.indexWhere((PlaceDoc d) => d.cursor == after) + 1;
    return all.skip(start).take(limit).toList();
  }

  Future<void> _write(void Function() action) async {
    if (hang) return Completer<void>().future;
    final Object? error = failWith;
    if (error != null) throw error;
    action();
  }

  @override
  Future<void> set(String uid, String id, Map<String, Object?> data) {
    return _write(() {
      final Map<String, Object?> existing =
          _places[uid]?[id] ?? const <String, Object?>{};
      final DateTime now = DateTime.now();
      (_places[uid] ??= {})[id] = {
        ...data,
        'createdAt': data['createdAt'] ?? existing['createdAt'] ?? now,
        'updatedAt': now,
      };
      _controller(uid).add(null);
    });
  }

  @override
  Future<void> delete(String uid, String id) {
    return _write(() {
      _places[uid]?.remove(id);
      _controller(uid).add(null);
    });
  }

  @override
  Future<bool> seedOnce(String uid, List<PlaceDoc> places) async {
    if (_seeded.contains(uid)) return false;
    _seeded.add(uid);
    seedCount++;
    for (final PlaceDoc doc in places) {
      (_places[uid] ??= {})[doc.id] = {
        ...doc.data,
        'createdAt': DateTime.now(),
      };
    }
    _controller(uid).add(null);
    return true;
  }
}
