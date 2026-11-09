import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/dev_launch_options.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/app_confirm_dialog.dart';
import '../../data/services/analytics_service.dart';
import '../favorites/screens/favorites_screen.dart';
import '../home/screens/home_screen.dart';
import '../places/bloc/places_bloc.dart';
import '../profile/screens/profile_screen.dart';

/// Container of the three main tabs.
///
/// [IndexedStack] keeps every tab alive, so scroll position and search text
/// survive switching tabs. The current tab index is *ephemeral* UI state and
/// stays here in `setState`; the catalog is app state and lives in
/// `PlacesBloc`, which the tabs read themselves — nothing is passed down.
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

  /// Screen names for Analytics: tabs live in an IndexedStack (no routes),
  /// so the navigator observer cannot see them — they are logged by hand.
  static const List<String> _tabScreenNames = ['home', 'favorites', 'profile'];

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.read<AnalyticsService>().logScreenView(_tabScreenNames[index]);
  }

  @override
  Widget build(BuildContext context) {
    // A failed save (the list itself is intact) is reported once, here.
    return BlocListener<PlacesBloc, PlacesState>(
      listenWhen: (PlacesState before, PlacesState now) =>
          now.status == PlacesStatus.loaded &&
          now.errorMessage != null &&
          before.errorMessage != now.errorMessage,
      listener: (BuildContext context, PlacesState state) {
        AppConfirmDialog.show(
          context,
          title: AppStrings.placesSaveErrorTitle,
          message: state.errorMessage!,
          confirmLabel: AppStrings.ok,
          cancelLabel: null,
        );
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: const [HomeScreen(), FavoritesScreen(), ProfileScreen()],
        ),
        bottomNavigationBar: AppBottomNavBar(
          items: _tabs,
          currentIndex: _currentIndex,
          onTap: _selectTab,
        ),
      ),
    );
  }
}
