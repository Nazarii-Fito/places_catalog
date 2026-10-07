import 'package:flutter/material.dart';

import '../../app/dev_launch_options.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../data/mock/mock_places.dart';
import '../../data/models/place.dart';
import '../favorites/screens/favorites_screen.dart';
import '../home/screens/home_screen.dart';
import '../places/place_details_args.dart';
import '../profile/screens/profile_screen.dart';

/// Container of the three main tabs and owner of the catalog list.
///
/// * [IndexedStack] keeps every tab alive, so scroll position and search
///   text survive switching tabs.
/// * The list of places is "lifted up" here: Home and Favorites receive it
///   as a parameter and report changes through callbacks, so a heart tapped
///   on Home is immediately visible on Favorites.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const List<AppNavItem> _tabs = [
    AppNavItem(icon: AppAssets.iconTabHome, label: AppStrings.tabHome),
    AppNavItem(
      icon: AppAssets.iconTabFavorites,
      label: AppStrings.tabFavorites,
    ),
    AppNavItem(icon: AppAssets.iconTabProfile, label: AppStrings.tabProfile),
  ];

  int _currentIndex = DevLaunchOptions.initialTab;
  List<Place> _places = List.of(mockPlaces);

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _toggleFavorite(Place place) {
    setState(() {
      _places = [
        for (final Place p in _places)
          p.id == place.id ? p.copyWith(isFavorite: !p.isFavorite) : p,
      ];
    });
  }

  void _deletePlace(Place place) {
    setState(() {
      _places = _places.where((Place p) => p.id != place.id).toList();
    });
  }

  void _openPlace(Place place) {
    Navigator.of(context).pushNamed(
      AppRoutes.placeDetails,
      arguments: PlaceDetailsArgs(
        place: place,
        onToggleFavorite: _toggleFavorite,
        onDelete: _deletePlace,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            places: _places,
            onToggleFavorite: _toggleFavorite,
            onOpenPlace: _openPlace,
          ),
          FavoritesScreen(
            places: _places,
            onToggleFavorite: _toggleFavorite,
            onOpenPlace: _openPlace,
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        items: _tabs,
        currentIndex: _currentIndex,
        onTap: _selectTab,
      ),
    );
  }
}
