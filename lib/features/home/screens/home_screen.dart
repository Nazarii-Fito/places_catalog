import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/place_card.dart';
import '../../../core/widgets/search_field.dart';
import '../../../data/mock/mock_places.dart';
import '../../../data/models/place.dart';
import '../home_filter.dart';
import '../widgets/catalog_summary_strip.dart';
import '../widgets/empty_places_view.dart';
import '../widgets/home_title_row.dart';

/// Home tab — "My Places" catalog (FR3, FR9).
///
/// State: the mock list (favourite flags can change), the search query and
/// the selected chip. `build` only *derives* the visible list from that
/// state; it never mutates anything (no side effects in `build`).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Place> _places = List.of(mockPlaces);
  HomeFilter _filter = HomeFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFavorite(Place place) {
    setState(() {
      _places = [
        for (final Place p in _places)
          p.id == place.id ? p.copyWith(isFavorite: !p.isFavorite) : p,
      ];
    });
  }

  bool _matchesQuery(Place place) {
    final String q = _query.trim().toLowerCase();
    return q.isEmpty ||
        place.name.toLowerCase().contains(q) ||
        place.subtitle.toLowerCase().contains(q);
  }

  // Lab 3 has no "Add place" / "Details" logic yet — these screens are
  // wired in stage 2, so the taps are intentionally no-ops for now.
  void _onAddPlace() {}

  void _onOpenPlace(Place place) {}

  @override
  Widget build(BuildContext context) {
    final List<Place> visible = _places
        .where(_filter.matches)
        .where(_matchesQuery)
        .toList();
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
              _Padded(child: HomeTitleRow(onAdd: _onAddPlace)),
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
              _Padded(child: CatalogSummaryStrip(count: visible.length)),
              const SizedBox(height: AppSpacing.m),
              if (visible.isEmpty)
                const EmptyPlacesView()
              else
                _Padded(
                  child: Column(
                    spacing: AppSpacing.ml,
                    children: visible
                        .map(
                          (Place place) => PlaceCard(
                            place: place,
                            onTap: () => _onOpenPlace(place),
                            onFavoriteToggle: () => _toggleFavorite(place),
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
