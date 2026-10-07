import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/app_text_link.dart';
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
  const FavoritesScreen({
    super.key,
    required this.places,
    required this.onToggleFavorite,
    required this.onOpenPlace,
  });

  final List<Place> places;
  final ValueChanged<Place> onToggleFavorite;
  final ValueChanged<Place> onOpenPlace;

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

  // Bulk editing of favourites is out of Lab 3 scope; the button is shown
  // as in the design but has no action yet.
  void _onEdit() {}

  @override
  Widget build(BuildContext context) {
    final List<Place> favorites = widget.places
        .where((Place p) => p.isFavorite)
        .toList();
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
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              top: insets.top,
              bottom: insets.bottom + 20,
            ),
            children: [
              _Padded(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        AppStrings.favoritesTitle,
                        style: AppTextStyles.title1,
                      ),
                    ),
                    AppTextLink(
                      label: AppStrings.edit,
                      onTap: _onEdit,
                      style: AppTextStyles.socialLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              _Padded(
                child: SearchField(
                  controller: _searchController,
                  hintText: AppStrings.searchFavoritesHint,
                  onChanged: (String value) => setState(() => _query = value),
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
                      label: '${AppStrings.filterAll} (${favorites.length})',
                      selected: category == null,
                      onTap: () => setState(() => _category = null),
                    ),
                    ...counts.entries.map(
                      (MapEntry<PlaceCategory, int> entry) => Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: CategoryChip(
                          // Map lookup is nullable — fall back to the enum
                          // name if a label is ever missing.
                          label:
                              '${AppStrings.categoryPlural[entry.key] ?? entry.key.name} '
                              '(${entry.value})',
                          selected: category == entry.key,
                          onTap: () => setState(() => _category = entry.key),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              if (visible.isEmpty)
                const EmptyState(
                  title: AppStrings.noFavoritesTitle,
                  subtitle: AppStrings.noFavoritesSubtitle,
                )
              else
                _Padded(
                  child: Column(
                    spacing: AppSpacing.m,
                    children: visible
                        .map(
                          (Place place) => PlaceCard(
                            place: place,
                            variant: PlaceCardVariant.favorites,
                            onTap: () => widget.onOpenPlace(place),
                            onFavoriteToggle: () =>
                                widget.onToggleFavorite(place),
                          ),
                        )
                        .toList(),
                  ),
                ),
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
