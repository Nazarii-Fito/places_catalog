import 'package:cloud_firestore/cloud_firestore.dart';

import 'places_document_store.dart';

/// [PlacesDocumentStore] on Cloud Firestore: `users/{uid}/places/{id}`.
///
/// The only class that touches the SDK. `DateTime` ↔ `Timestamp` is
/// converted here so the rest of the code stays SDK-free.
class FirestorePlacesDocumentStore implements PlacesDocumentStore {
  FirestorePlacesDocumentStore(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _places(String uid) =>
      _user(uid).collection('places');

  /// Ordered by visit date only: a single-field order needs no composite
  /// index. Ties are broken by the repository (createdAt, id).
  Query<Map<String, dynamic>> _ordered(String uid) =>
      _places(uid).orderBy('visitDate', descending: true);

  @override
  String newId(String uid) => _places(uid).doc().id;

  @override
  Stream<List<PlaceDoc>> watch(String uid) {
    return _ordered(uid).snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) => [
        for (final QueryDocumentSnapshot<Map<String, dynamic>> d
            in snapshot.docs)
          PlaceDoc(d.id, _fromFirestore(d.data()), cursor: d),
      ],
    );
  }

  @override
  Future<List<PlaceDoc>> fetchPage(
    String uid, {
    required int limit,
    Object? after,
  }) async {
    Query<Map<String, dynamic>> query = _ordered(uid).limit(limit);
    if (after is DocumentSnapshot) query = query.startAfterDocument(after);
    final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
    return [
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d in snapshot.docs)
        PlaceDoc(d.id, _fromFirestore(d.data()), cursor: d),
    ];
  }

  @override
  Future<void> set(String uid, String id, Map<String, Object?> data) {
    final Map<String, Object?> body = {
      ..._toFirestore(data),
      // The server's clock, not the phone's: ordering stays trustworthy.
      'createdAt': data['createdAt'] == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(data['createdAt']! as DateTime),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    return _places(uid).doc(id).set(body);
  }

  @override
  Future<void> delete(String uid, String id) => _places(uid).doc(id).delete();

  @override
  Future<bool> seedOnce(String uid, List<PlaceDoc> places) {
    return _db.runTransaction<bool>((Transaction tx) async {
      final DocumentSnapshot<Map<String, dynamic>> user = await tx.get(
        _user(uid),
      );
      if (user.data()?['seededAt'] != null) return false;
      for (final PlaceDoc doc in places) {
        tx.set(_places(uid).doc(doc.id), {
          ..._toFirestore(doc.data),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      tx.set(_user(uid), {
        'seededAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    });
  }

  // ---- DateTime <-> Timestamp, recursively -------------------------------

  static Object? _convertOut(Object? value) {
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is Map) {
      return {
        for (final MapEntry<dynamic, dynamic> e in value.entries)
          e.key: _convertOut(e.value),
      };
    }
    if (value is List) return [for (final Object? v in value) _convertOut(v)];
    return value;
  }

  static Object? _convertIn(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is Map) {
      return {
        for (final MapEntry<dynamic, dynamic> e in value.entries)
          e.key: _convertIn(e.value),
      };
    }
    if (value is List) return [for (final Object? v in value) _convertIn(v)];
    return value;
  }

  static Map<String, Object?> _toFirestore(Map<String, Object?> data) => {
    for (final MapEntry<String, Object?> e in data.entries)
      e.key: _convertOut(e.value),
  };

  static Map<String, Object?> _fromFirestore(Map<String, dynamic> data) => {
    for (final MapEntry<String, dynamic> e in data.entries)
      e.key: _convertIn(e.value),
  };
}
