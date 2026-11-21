/// A stored place document: its id and its fields as a plain map.
class PlaceDoc {
  const PlaceDoc(this.id, this.data, {this.cursor});

  final String id;
  final Map<String, Object?> data;

  /// Backend-specific position of this document, used to continue paging.
  final Object? cursor;
}

/// The thin layer between the repository and the document database.
///
/// It only moves maps in and out and knows nothing about [Place]. That keeps
/// the SDK in exactly one small class (`FirestorePlacesDocumentStore`) and
/// lets the repository logic — seeding once, sorting, error mapping,
/// write timeout — be tested against `InMemoryPlacesDocumentStore`.
abstract interface class PlacesDocumentStore {
  /// A new unique document id (generated locally, no network).
  String newId(String uid);

  /// Every place of [uid], ordered by `visitDate` (newest first), re-emitted
  /// on each change.
  Stream<List<PlaceDoc>> watch(String uid);

  /// Up to [limit] places ordered like [watch], after the [after] cursor.
  Future<List<PlaceDoc>> fetchPage(
    String uid, {
    required int limit,
    Object? after,
  });

  /// Writes the document. `createdAt` is added when [data] has none;
  /// `updatedAt` is always set to the time of the write.
  Future<void> set(String uid, String id, Map<String, Object?> data);

  Future<void> delete(String uid, String id);

  /// Writes [places] and marks the user as seeded, **atomically and only if
  /// the user was not seeded before**. Returns whether this call seeded.
  /// The flag is what stops the demo catalog from coming back after the user
  /// deletes everything.
  Future<bool> seedOnce(String uid, List<PlaceDoc> places);
}
