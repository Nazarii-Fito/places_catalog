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

  group('PlacesBloc', () {
    blocTest<PlacesBloc, PlacesState>(
      'load: loading → loaded with the catalog',
      build: () => make(InMemoryPlacesRepository()),
      act: (PlacesBloc b) => b.add(const PlacesLoadRequested()),
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
      expect: () => [
        const PlacesState(status: PlacesStatus.loading),
        isA<PlacesState>()
            .having((s) => s.status, 'status', PlacesStatus.failure)
            .having((s) => s.errorMessage, 'message', isNotNull),
      ],
    );

    blocTest<PlacesBloc, PlacesState>(
      'retry after a failure loads the catalog',
      build: () {
        final InMemoryPlacesRepository repo = InMemoryPlacesRepository(
          failLoad: true,
        );
        return make(repo);
      },
      act: (PlacesBloc b) async {
        b.add(const PlacesLoadRequested());
        await b.stream.firstWhere(
          (PlacesState s) => s.status == PlacesStatus.failure,
        );
        (b.repositoryForTest as InMemoryPlacesRepository).failLoad = false;
        b.add(const PlacesLoadRequested());
      },
      skip: 2,
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const PlacesState(status: PlacesStatus.loading),
        isA<PlacesState>().having((s) => s.status, 's', PlacesStatus.loaded),
      ],
    );

    blocTest<PlacesBloc, PlacesState>(
      'create appends the place and saves it',
      build: () => make(InMemoryPlacesRepository()),
      seed: () =>
          PlacesState(status: PlacesStatus.loaded, places: List.of(mockPlaces)),
      act: (PlacesBloc b) => b.add(PlaceCreated(fresh)),
      verify: (PlacesBloc b) {
        expect(b.state.places.last.id, 'fresh');
        expect(b.state.places.length, mockPlaces.length + 1);
      },
    );

    blocTest<PlacesBloc, PlacesState>(
      'update replaces the place with the same id',
      build: () => make(InMemoryPlacesRepository()),
      seed: () =>
          PlacesState(status: PlacesStatus.loaded, places: List.of(mockPlaces)),
      act: (PlacesBloc b) =>
          b.add(PlaceUpdated(mockPlaces.first.copyWith(name: 'Renamed'))),
      verify: (PlacesBloc b) {
        expect(b.state.byId(mockPlaces.first.id)!.name, 'Renamed');
        expect(b.state.places.length, mockPlaces.length);
      },
    );

    blocTest<PlacesBloc, PlacesState>(
      'delete removes the place',
      build: () => make(InMemoryPlacesRepository()),
      seed: () =>
          PlacesState(status: PlacesStatus.loaded, places: List.of(mockPlaces)),
      act: (PlacesBloc b) => b.add(PlaceDeleted(mockPlaces.first.id)),
      verify: (PlacesBloc b) {
        expect(b.state.byId(mockPlaces.first.id), isNull);
        expect(b.state.places.length, mockPlaces.length - 1);
      },
    );

    blocTest<PlacesBloc, PlacesState>(
      'toggle favourite flips the flag and logs analytics',
      build: () => make(InMemoryPlacesRepository()),
      seed: () =>
          PlacesState(status: PlacesStatus.loaded, places: List.of(mockPlaces)),
      act: (PlacesBloc b) => b.add(PlaceFavoriteToggled(mockPlaces.first.id)),
      verify: (PlacesBloc b) {
        expect(b.state.byId(mockPlaces.first.id)!.isFavorite, isFalse);
        expect(analytics.events, ['fav:${mockPlaces.first.id}:false']);
      },
    );

    blocTest<PlacesBloc, PlacesState>(
      'a failed save keeps the list and reports an error once',
      build: () => make(_FailingSaves()),
      seed: () =>
          PlacesState(status: PlacesStatus.loaded, places: List.of(mockPlaces)),
      act: (PlacesBloc b) => b.add(PlaceCreated(fresh)),
      verify: (PlacesBloc b) {
        expect(b.state.places.length, mockPlaces.length);
        expect(b.state.status, PlacesStatus.loaded);
        expect(b.state.errorMessage, isNotNull);
      },
    );

    blocTest<PlacesBloc, PlacesState>(
      'opening a place only logs analytics',
      build: () => make(InMemoryPlacesRepository()),
      seed: () =>
          PlacesState(status: PlacesStatus.loaded, places: List.of(mockPlaces)),
      act: (PlacesBloc b) => b.add(PlaceOpened(mockPlaces.first.id)),
      expect: () => <PlacesState>[],
      verify: (_) => expect(analytics.events, ['open:${mockPlaces.first.id}']),
    );
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
