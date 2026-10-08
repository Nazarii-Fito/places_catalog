import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/place_card.dart';
import '../../../core/widgets/search_field.dart';
import '../../../data/models/place.dart';
import '../home_filter.dart';
import '../home_sort.dart';
import '../widgets/catalog_summary_strip.dart';
import '../widgets/home_title_row.dart';

/// Home tab — "My Places" catalog (FR3, FR9).
///
/// The catalog itself comes from `MainShell` ([places]); this screen only
/// owns UI state — the search query and the selected chip. `build` derives
/// the visible list from them and never mutates anything (no side effects
/// in `build`).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.places,
    required this.onToggleFavorite,
    required this.onOpenPlace,
  });

  final List<Place> places;
  final ValueChanged<Place> onToggleFavorite;
  final ValueChanged<Place> onOpenPlace;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  HomeFilter _filter = HomeFilter.all;
  HomeSort _sort = HomeSort.recent;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(Place place) {
    final String q = _query.trim().toLowerCase();
    return q.isEmpty ||
        place.name.toLowerCase().contains(q) ||
        place.subtitle.toLowerCase().contains(q);
  }

  void _openAddPlace() => Navigator.of(context).pushNamed(AppRoutes.addPlace);

  @override
  Widget build(BuildContext context) {
    // A new list is filtered and sorted — widget.places stays untouched.
    final List<Place> visible =
        widget.places.where(_filter.matches).where(_matchesQuery).toList()
          ..sort(_sort.compare);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavHeader(title: AppStrings.tabHome),
      // Builder: read the insets *inside* this Scaffold — they include the
      // translucent header (top) and the tab bar of MainShell (bottom).
      body: Builder(
        builder: (BuildContext context) {
          final EdgeInsets insets = MediaQuery.paddingOf(context);
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              top: insets.top + AppSpacing.sm,
              bottom: insets.bottom + 20,
            ),
            children: [
              _Padded(child: HomeTitleRow(onAdd: _openAddPlace)),
              const SizedBox(height: AppSpacing.m),
              _Padded(
                child: SearchField(
                  controller: _searchController,
                  hintText: AppStrings.searchHint,
                  onChanged: (String value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
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
                    final HomeFilter filter = HomeFilter.values[index];
                    return CategoryChip(
                      label: filter.label,
                      selected: filter == _filter,
                      onTap: () => setState(() => _filter = filter),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              _Padded(
                child: CatalogSummaryStrip(
                  count: visible.length,
                  sort: _sort,
                  onSortSelected: (HomeSort sort) =>
                      setState(() => _sort = sort),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              if (visible.isEmpty)
                const EmptyState(
                  title: AppStrings.emptyTitle,
                  subtitle: AppStrings.emptySubtitle,
                )
              else
                _Padded(
                  child: Column(
                    spacing: AppSpacing.ml,
                    children: visible
                        .map(
                          (Place place) => PlaceCard(
                            place: place,
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
