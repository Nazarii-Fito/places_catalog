import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes/app_routes.dart';
import '../../places/bloc/places_bloc.dart';
import '../../places/place_details_args.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/place_card.dart';
import '../../../core/widgets/search_field.dart';
import '../../../data/models/place.dart';
import '../../../data/models/place_category.dart';

/// Favorites tab (FR10): places with the heart on, filtered by category.
///
/// The chip row is generated from a `Map<PlaceCategory, int>` of counts,
/// so it always reflects the current favourites ("Cafes (2)").
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// `null` means "All".
  PlaceCategory? _category;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<PlaceCategory, int> _countByCategory(List<Place> places) {
    final Map<PlaceCategory, int> counts = {};
    for (final Place place in places) {
      counts[place.category] = (counts[place.category] ?? 0) + 1;
    }
    return counts;
  }

  bool _matchesQuery(Place place) {
    final String q = _query.trim().toLowerCase();
    return q.isEmpty || place.name.toLowerCase().contains(q);
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
    // Favorites is a *view* of the same catalog Home shows: one source of
    // truth, so a heart tapped anywhere is reflected here at once.
    final List<Place> favorites = context.select(
      (PlacesBloc b) =>
          b.state.places.where((Place p) => p.isFavorite).toList(),
    );
    final Map<PlaceCategory, int> counts = _countByCategory(favorites);
    // A category whose last favourite was removed falls back to "All".
    final PlaceCategory? category = counts.containsKey(_category)
        ? _category
        : null;
    final List<Place> visible = favorites
        .where((Place p) => category == null || p.category == category)
        .where(_matchesQuery)
        .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavHeader(title: AppStrings.favoritesHeader),
      body: Builder(
        builder: (BuildContext context) {
          final EdgeInsets insets = MediaQuery.paddingOf(context);
          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(top: insets.top),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // No "Edit" button: the heart on each card already
                      // removes a place from favourites, so a bulk-edit mode
                      // would duplicate it.
                      const _Padded(
                        child: SizedBox(
                          height: AppSpacing.minTapTarget,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppStrings.favoritesTitle,
                              style: AppTextStyles.title1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      _Padded(
                        child: SearchField(
                          controller: _searchController,
                          hintText: AppStrings.searchFavoritesHint,
                          onChanged: (String value) =>
                              setState(() => _query = value),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screen,
                          ),
                          children: [
                            CategoryChip(
                              label:
                                  '${AppStrings.filterAll} (${favorites.length})',
                              selected: category == null,
                              onTap: () => setState(() => _category = null),
                            ),
                            ...counts.entries.map(
                              (MapEntry<PlaceCategory, int> entry) => Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.sm,
                                ),
                                child: CategoryChip(
                                  // Map lookup is nullable — fall back to the
                                  // enum name if a label is ever missing.
                                  label:
                                      '${AppStrings.categoryPlural[entry.key] ?? entry.key.name} '
                                      '(${entry.value})',
                                  selected: category == entry.key,
                                  onTap: () =>
                                      setState(() => _category = entry.key),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                    ],
                  ),
                ),
              ),
              if (visible.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(
                    title: AppStrings.noFavoritesTitle,
                    subtitle: AppStrings.noFavoritesSubtitle,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                  ),
                  sliver: SliverList.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.m),
                    itemBuilder: (BuildContext context, int index) {
                      final Place place = visible[index];
                      return PlaceCard(
                        key: ValueKey<String>(place.id),
                        place: place,
                        variant: PlaceCardVariant.favorites,
                        onTap: () => _openPlace(place),
                        onFavoriteToggle: () => context.read<PlacesBloc>().add(
                          PlaceFavoriteToggled(place.id),
                        ),
                      );
                    },
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: insets.bottom + 20)),
            ],
          );
        },
      ),
    );
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
