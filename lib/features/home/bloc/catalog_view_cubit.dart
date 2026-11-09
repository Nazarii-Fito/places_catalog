// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/place.dart';
import '../../../data/repositories/settings_repository.dart';
import '../home_filter.dart';
import '../home_sort.dart';

/// How the Home list is shown: search text, category filter, sort order.
final class CatalogViewState extends Equatable {
  const CatalogViewState({
    this.query = '',
    this.filter = HomeFilter.all,
    this.sort = HomeSort.recent,
  });

  /// Ephemeral: typed in the search field, deliberately never persisted.
  final String query;
  final HomeFilter filter;
  final HomeSort sort;

  CatalogViewState copyWith({
    String? query,
    HomeFilter? filter,
    HomeSort? sort,
  }) {
    return CatalogViewState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [query, filter, sort];
}

/// A *Cubit*, not a Bloc: three trivial setters with no event history to
/// model, so plain methods are enough (no event classes, less boilerplate).
///
/// [filter] and [sort] are remembered per user through the
/// [SettingsRepository] and restored on creation; [query] is not.
class CatalogViewCubit extends Cubit<CatalogViewState> {
  CatalogViewCubit({required this.uid, required SettingsRepository settings})
    : _settings = settings,
      super(const CatalogViewState()) {
    _restore();
  }

  final String uid;
  final SettingsRepository _settings;

  Future<void> _restore() async {
    final CatalogViewPrefs prefs = await _settings.loadCatalogView(uid);
    // Unknown names (e.g. written by a newer app version) are ignored.
    final HomeFilter? filter = HomeFilter.values.asNameMap()[prefs.filter];
    final HomeSort? sort = HomeSort.values.asNameMap()[prefs.sort];
    if (isClosed) return;
    emit(state.copyWith(filter: filter, sort: sort));
  }

  void setQuery(String query) => emit(state.copyWith(query: query));

  void setFilter(HomeFilter filter) {
    emit(state.copyWith(filter: filter));
    _settings.saveCatalogView(uid, filter: filter.name);
  }

  void setSort(HomeSort sort) {
    emit(state.copyWith(sort: sort));
    _settings.saveCatalogView(uid, sort: sort.name);
  }
}

/// The places Home shows: a pure function of the catalog and the view, so it
/// is trivial to test and `build` has no side effects. Returns a new list.
List<Place> visiblePlaces(List<Place> places, CatalogViewState view) {
  final String q = view.query.trim().toLowerCase();
  return places
      .where(view.filter.matches)
      .where(
        (Place p) =>
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.subtitle.toLowerCase().contains(q),
      )
      .toList()
    ..sort(view.sort.compare);
}
