import 'package:shared_preferences/shared_preferences.dart';

import 'settings_repository.dart';

/// [SettingsRepository] on top of `shared_preferences`.
///
/// The classic [SharedPreferences] (instance obtained once with
/// `getInstance()` in `main`) is used because it is what the course
/// material describes and it is trivially mockable in tests.
///
/// Keys carry the uid (`<uid>.catalog.filter`) so two accounts on one
/// device keep separate settings. SharedPreferences gives no durability
/// guarantee for a write that is interrupted, which is acceptable for a
/// sort order — it would never be used for the catalog itself.
class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static String _filterKey(String uid) => '$uid.catalog.filter';
  static String _sortKey(String uid) => '$uid.catalog.sort';

  @override
  Future<CatalogViewPrefs> loadCatalogView(String uid) async =>
      CatalogViewPrefs(
        filter: _prefs.getString(_filterKey(uid)),
        sort: _prefs.getString(_sortKey(uid)),
      );

  @override
  Future<void> saveCatalogView(
    String uid, {
    String? filter,
    String? sort,
  }) async {
    if (filter != null) await _prefs.setString(_filterKey(uid), filter);
    if (sort != null) await _prefs.setString(_sortKey(uid), sort);
  }
}
