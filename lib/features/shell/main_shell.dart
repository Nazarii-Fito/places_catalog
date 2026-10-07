import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../favorites/screens/favorites_screen.dart';
import '../home/screens/home_screen.dart';
import '../profile/screens/profile_screen.dart';

/// Container of the three main tabs.
///
/// [IndexedStack] keeps every tab alive, so scroll position and search text
/// survive switching tabs. The bar is drawn over the content
/// (`extendBody`) to get the translucent iOS look from Figma.
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

  int _currentIndex = 0;

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
