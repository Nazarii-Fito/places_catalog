import 'settings_repository.dart';

/// Memory-only settings for tests and the `FAKE_AUTH` screenshot mode.
class InMemorySettingsRepository implements SettingsRepository {
  final Map<String, CatalogViewPrefs> _byUser = {};

  @override
  Future<CatalogViewPrefs> loadCatalogView(String uid) async =>
      _byUser[uid] ?? const CatalogViewPrefs();

  @override
  Future<void> saveCatalogView(
    String uid, {
    String? filter,
    String? sort,
  }) async {
    final CatalogViewPrefs old = _byUser[uid] ?? const CatalogViewPrefs();
    _byUser[uid] = CatalogViewPrefs(
      filter: filter ?? old.filter,
      sort: sort ?? old.sort,
    );
  }
}
