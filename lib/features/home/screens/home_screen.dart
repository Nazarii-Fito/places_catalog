import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes/app_routes.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/place_card.dart';
import '../../../core/widgets/search_field.dart';
import '../../../data/models/place.dart';
import '../../../core/widgets/error_state.dart';
import '../../places/bloc/places_bloc.dart';
import '../../places/place_details_args.dart';
import '../bloc/catalog_view_cubit.dart';
import '../home_filter.dart';
import '../widgets/catalog_summary_strip.dart';
import '../widgets/home_title_row.dart';

/// Home tab — "My Places" catalog (FR3, FR9).
///
/// * The catalog comes from `PlacesBloc` (loading / failure / loaded).
/// * Filter, sort and search come from `CatalogViewCubit`; the visible
///   list is the pure function `visiblePlaces(places, view)`.
/// * Only the search `TextEditingController` is ephemeral and stays in
///   this `State`.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addPlace() async {
    final PlacesBloc bloc = context.read<PlacesBloc>();
    final Object? result = await Navigator.of(context)
        .pushNamed(AppRoutes.addPlace);
    if (result is Place) bloc.add(PlaceCreated(result));
  }

  void _openPlace(Place place) {
    context.read<PlacesBloc>().add(PlaceOpened(place.id));
    Navigator.of(context).pushNamed(
      AppRoutes.placeDetails,
      arguments: PlaceDetailsArgs(placeId: place.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CatalogViewCubit view = context.read<CatalogViewCubit>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavHeader(title: AppStrings.tabHome),
      // Builder: read the insets *inside* this Scaffold — they include the
      // translucent header (top) and the tab bar of MainShell (bottom).
      body: Builder(
        builder: (BuildContext context) {
          final EdgeInsets insets = MediaQuery.paddingOf(context);
          // CustomScrollView + slivers: the header blocks are single boxes
          // (SliverToBoxAdapter) and the cards are built lazily by
          // SliverList, so a long catalog only builds what is on screen.
          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(top: insets.top + AppSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _Padded(child: HomeTitleRow(onAdd: _addPlace)),
                      const SizedBox(height: AppSpacing.m),
                      _Padded(
                        child: SearchField(
                          controller: _searchController,
                          hintText: AppStrings.searchHint,
                          onChanged: view.setQuery,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      BlocBuilder<CatalogViewCubit, CatalogViewState>(
                        buildWhen: (a, b) => a.filter != b.filter,
                        builder: (BuildContext context, CatalogViewState s) =>
                            SizedBox(
                              height: 40,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.screen,
                                ),
                                itemCount: HomeFilter.values.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: AppSpacing.sm),
                                itemBuilder: (BuildContext context, int index) {
                                  final HomeFilter filter =
                                      HomeFilter.values[index];
                                  return CategoryChip(
                                    label: filter.label,
                                    selected: filter == s.filter,
                                    onTap: () => view.setFilter(filter),
                                  );
                                },
                              ),
                            ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      _Padded(
                        child: BlocBuilder<PlacesBloc, PlacesState>(
                          builder: (BuildContext context, PlacesState p) =>
                              BlocBuilder<CatalogViewCubit, CatalogViewState>(
                                builder:
                                    (
                                      BuildContext context,
                                      CatalogViewState s,
                                    ) => CatalogSummaryStrip(
                                      count: visiblePlaces(p.places, s).length,
                                      sort: s.sort,
                                      onSortSelected: view.setSort,
                                    ),
                              ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                    ],
                  ),
                ),
              ),
              ..._body(context),
              SliverToBoxAdapter(child: SizedBox(height: insets.bottom + 20)),
            ],
          );
        },
      ),
    );
  }

  /// The part below the filters. Built from both blocs; a `BlocBuilder`
  /// around a *sliver* is not possible inside a plain list, so each state
  /// is wrapped in a [SliverToBoxAdapter] or [SliverMainAxisGroup].
  List<Widget> _body(BuildContext context) {
    return [
      BlocBuilder<PlacesBloc, PlacesState>(
        builder: (BuildContext context, PlacesState places) {
          switch (places.status) {
            case PlacesStatus.initial:
            case PlacesStatus.loading:
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(child: CupertinoActivityIndicator(radius: 14)),
                ),
              );
            case PlacesStatus.failure:
              return SliverToBoxAdapter(
                child: ErrorState(
                  message: places.errorMessage ?? AppStrings.errorUnknown,
                  onRetry: () => context.read<PlacesBloc>().add(
                    const PlacesLoadRequested(),
                  ),
                ),
              );
            case PlacesStatus.loaded:
              return BlocBuilder<CatalogViewCubit, CatalogViewState>(
                builder: (BuildContext context, CatalogViewState view) {
                  // A new list is filtered and sorted; the bloc's list is
                  // never touched.
                  final List<Place> visible = visiblePlaces(
                    places.places,
                    view,
                  );
                  if (visible.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: EmptyState(
                        title: AppStrings.emptyTitle,
                        subtitle: AppStrings.emptySubtitle,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.ml),
                      itemBuilder: (BuildContext context, int index) {
                        final Place place = visible[index];
                        return PlaceCard(
                          // A stable key keeps each card's state with its
                          // place when the list is re-sorted or filtered.
                          key: ValueKey<String>(place.id),
                          place: place,
                          onTap: () => _openPlace(place),
                          onFavoriteToggle: () => context
                              .read<PlacesBloc>()
                              .add(PlaceFavoriteToggled(place.id)),
                        );
                      },
                    ),
                  );
                },
              );
          }
        },
      ),
    ];
  }
}

class _Padded extends StatelessWidget {
  const _Padded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: child,
    );
  }
}
