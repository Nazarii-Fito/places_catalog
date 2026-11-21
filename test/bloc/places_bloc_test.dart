import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/data/mock/mock_places.dart';
import 'package:places_catalog/data/models/place.dart';
import 'package:places_catalog/data/repositories/in_memory_places_repository.dart';
import 'package:places_catalog/data/repositories/in_memory_settings_repository.dart';
import 'package:places_catalog/data/repositories/places_repository.dart';
import 'package:places_catalog/data/services/analytics_service.dart';
import 'package:places_catalog/data/services/crash_reporter.dart';
import 'package:places_catalog/features/home/bloc/catalog_view_cubit.dart';
import 'package:places_catalog/features/home/home_filter.dart';
import 'package:places_catalog/features/home/home_sort.dart';
import 'package:places_catalog/features/places/bloc/places_bloc.dart';

class _RecordingAnalytics extends NoopAnalyticsService {
  _RecordingAnalytics();
  final List<String> events = [];

  @override
  Future<void> logPlaceFavoriteToggled({
    required String placeId,
    required bool isFavorite,
  }) async => events.add('fav:$placeId:$isFavorite');

  @override
  Future<void> logPlaceOpened({
    required String placeId,
    required String category,
  }) async => events.add('open:$placeId');
}

/// A repository whose writes always fail (disk full, permissions…).
class _FailingSaves extends InMemoryPlacesRepository {
  @override
  Future<void> savePlace(String uid, Place place) =>
      Future.error(StateError('disk full'));

  @override
  Future<void> deletePlace(String uid, String placeId) =>
      Future.error(StateError('disk full'));
}

void main() {
  late _RecordingAnalytics analytics;
  final Place fresh = Place.fromJson({
    ...mockPlaces.first.toJson(),
    'id': 'fresh',
    'name': 'Fresh Place',
    'isFavorite': false,
  });

  PlacesBloc make(PlacesRepository repo) => PlacesBloc(
    uid: 'u1',
    repository: repo,
    analytics: analytics,
    crashReporter: const NoopCrashReporter(),
  );

  setUp(() => analytics = _RecordingAnalytics());

  /// Starts the bloc and waits until the catalog has arrived.
  Future<void> loaded(PlacesBloc b) async {
    b.add(const PlacesLoadRequested());
    await b.stream.firstWhere(
      (PlacesState s) => s.status == PlacesStatus.loaded,
    );
  }

  group('PlacesBloc', () {
    blocTest<PlacesBloc, PlacesState>(
      'load: loading → loaded with the catalog',
      build: () => make(InMemoryPlacesRepository()),
      act: (PlacesBloc b) => b.add(const PlacesLoadRequested()),
      wait: const Duration(milliseconds: 30),
      expect: () => [
        const PlacesState(status: PlacesStatus.loading),
        isA<PlacesState>()
            .having((s) => s.status, 'status', PlacesStatus.loaded)
            .having((s) => s.places.length, 'places', mockPlaces.length),
      ],
    );

    blocTest<PlacesBloc, PlacesState>(
      'load failure: loading → failure with a message',
      build: () => make(InMemoryPlacesRepository(failLoad: true)),
      act: (PlacesBloc b) => b.add(const PlacesLoadRequested()),
      wait: const Duration(milliseconds: 30),
      expect: () => [
        const PlacesState(status: PlacesStatus.loading),
        isA<PlacesState>()
            .having((s) => s.status, 'status', PlacesStatus.failure)
            .having((s) => s.errorMessage, 'message', isNotNull),
      ],
    );

    test('retry after a failure loads the catalog', () async {
      final InMemoryPlacesRepository repo = InMemoryPlacesRepository(
        failLoad: true,
      );
      final PlacesBloc bloc = make(repo)..add(const PlacesLoadRequested());
      await bloc.stream.firstWhere(
        (PlacesState s) => s.status == PlacesStatus.failure,
      );
      repo.failLoad = false;
      bloc.add(const PlacesLoadRequested());
      final PlacesState ok = await bloc.stream.firstWhere(
        (PlacesState s) => s.status == PlacesStatus.loaded,
      );
      expect(ok.places.length, mockPlaces.length);
      await bloc.close();
    });

    test('a change from elsewhere reaches the state (live stream)', () async {
      final InMemoryPlacesRepository repo = InMemoryPlacesRepository();
      final PlacesBloc bloc = make(repo);
      await loaded(bloc);
      // Another "device" writes straight to the repository.
      await repo.savePlace('u1', fresh);
      final PlacesState s = await bloc.stream.firstWhere(
        (PlacesState s) => s.byId('fresh') != null,
      );
      expect(s.places.length, mockPlaces.length + 1);
      await bloc.close();
    });

    test('create appends the place and saves it', () async {
      final PlacesBloc bloc = make(InMemoryPlacesRepository());
      await loaded(bloc);
      bloc.add(PlaceCreated(fresh));
      final PlacesState s = await bloc.stream.firstWhere(
        (PlacesState s) => s.byId('fresh') != null,
      );
      expect(s.places.length, mockPlaces.length + 1);
      await bloc.close();
    });

    test('update replaces the place with the same id', () async {
      final PlacesBloc bloc = make(InMemoryPlacesRepository());
      await loaded(bloc);
      bloc.add(PlaceUpdated(mockPlaces.first.copyWith(name: 'Renamed')));
      final PlacesState s = await bloc.stream.firstWhere(
        (PlacesState s) => s.byId(mockPlaces.first.id)?.name == 'Renamed',
      );
      expect(s.places.length, mockPlaces.length);
      await bloc.close();
    });

    test('delete removes the place', () async {
      final PlacesBloc bloc = make(InMemoryPlacesRepository());
      await loaded(bloc);
      bloc.add(PlaceDeleted(mockPlaces.first.id));
      final PlacesState s = await bloc.stream.firstWhere(
        (PlacesState s) => s.byId(mockPlaces.first.id) == null,
      );
      expect(s.places.length, mockPlaces.length - 1);
      await bloc.close();
    });

    test('toggle favourite flips the flag and logs analytics', () async {
      final PlacesBloc bloc = make(InMemoryPlacesRepository());
      await loaded(bloc);
      bloc.add(PlaceFavoriteToggled(mockPlaces.first.id));
      final PlacesState s = await bloc.stream.firstWhere(
        (PlacesState s) => s.byId(mockPlaces.first.id)?.isFavorite == false,
      );
      expect(s.byId(mockPlaces.first.id)!.isFavorite, isFalse);
      expect(analytics.events, ['fav:${mockPlaces.first.id}:false']);
      await bloc.close();
    });

    test('a failed save keeps the list and reports an error', () async {
      final PlacesBloc bloc = make(_FailingSaves());
      await loaded(bloc);
      bloc.add(PlaceCreated(fresh));
      final PlacesState s = await bloc.stream.firstWhere(
        (PlacesState s) => s.errorMessage != null,
      );
      expect(s.places.length, mockPlaces.length);
      expect(s.status, PlacesStatus.loaded);
      await bloc.close();
    });

    test('opening a place only logs analytics', () async {
      final PlacesBloc bloc = make(InMemoryPlacesRepository());
      await loaded(bloc);
      final PlacesState before = bloc.state;
      bloc.add(PlaceOpened(mockPlaces.first.id));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, before);
      expect(analytics.events, ['open:${mockPlaces.first.id}']);
      await bloc.close();
    });

    test('closing the bloc cancels the subscription at once', () async {
      final PlacesBloc bloc = make(InMemoryPlacesRepository());
      await loaded(bloc);
      await bloc.close().timeout(const Duration(seconds: 2));
    });
  });

  group('CatalogViewCubit', () {
    test('restores the saved filter and sort, not the query', () async {
      final InMemorySettingsRepository settings = InMemorySettingsRepository();
      await settings.saveCatalogView('u1', filter: 'cafes', sort: 'name');
      final CatalogViewCubit cubit = CatalogViewCubit(
        uid: 'u1',
        settings: settings,
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.filter, HomeFilter.cafes);
      expect(cubit.state.sort, HomeSort.name);
      expect(cubit.state.query, '');
    });

    test('ignores unknown saved names', () async {
      final InMemorySettingsRepository settings = InMemorySettingsRepository();
      await settings.saveCatalogView('u1', filter: 'nope', sort: 'nope');
      final CatalogViewCubit cubit = CatalogViewCubit(
        uid: 'u1',
        settings: settings,
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, const CatalogViewState());
    });

    blocTest<CatalogViewCubit, CatalogViewState>(
      'setFilter / setSort emit and persist; setQuery does not persist',
      build: () =>
          CatalogViewCubit(uid: 'u1', settings: InMemorySettingsRepository()),
      act: (CatalogViewCubit c) => c
        ..setFilter(HomeFilter.museums)
        ..setSort(HomeSort.rating)
        ..setQuery('abc'),
      expect: () => [
        const CatalogViewState(filter: HomeFilter.museums),
        const CatalogViewState(
          filter: HomeFilter.museums,
          sort: HomeSort.rating,
        ),
        const CatalogViewState(
          filter: HomeFilter.museums,
          sort: HomeSort.rating,
          query: 'abc',
        ),
      ],
    );

    test('each user has their own saved view', () async {
      final InMemorySettingsRepository settings = InMemorySettingsRepository();
      CatalogViewCubit(
        uid: 'a',
        settings: settings,
      ).setFilter(HomeFilter.cafes);
      await Future<void>.delayed(Duration.zero);
      final CatalogViewCubit other = CatalogViewCubit(
        uid: 'b',
        settings: settings,
      );
      await Future<void>.delayed(Duration.zero);
      expect(other.state.filter, HomeFilter.all);
    });

    test('visiblePlaces filters, searches and sorts without mutating', () {
      final List<Place> input = List.of(mockPlaces);
      final List<Place> out = visiblePlaces(
        input,
        const CatalogViewState(
          filter: HomeFilter.restaurants,
          sort: HomeSort.name,
        ),
      );
      expect(out.map((Place p) => p.name), [
        'Kurobuta Ramen',
        'Osteria Del Sole',
      ]);
      expect(input, mockPlaces);
      expect(
        visiblePlaces(input, const CatalogViewState(query: 'ramen')).length,
        1,
      );
    });
  });
}
