/// The Home list settings that survive a restart.
///
/// Stored as enum *names* (strings) so the data layer does not depend on
/// the Home feature's `HomeFilter` / `HomeSort`; the cubit parses them.
class CatalogViewPrefs {
  const CatalogViewPrefs({this.filter, this.sort});

  final String? filter;
  final String? sort;
}

/// Small per-user preferences (key–value data, the SharedPreferences use
/// case). The search text is deliberately *not* stored: it is ephemeral.
abstract interface class SettingsRepository {
  Future<CatalogViewPrefs> loadCatalogView(String uid);

  Future<void> saveCatalogView(String uid, {String? filter, String? sort});
}
