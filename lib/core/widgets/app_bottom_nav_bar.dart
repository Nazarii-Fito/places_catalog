import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_svg_icon.dart';

/// One destination of [AppBottomNavBar].
class AppNavItem {
  const AppNavItem({required this.icon, required this.label});

  final String icon;
  final String label;
}

/// iOS-style translucent tab bar (Home / Favorites / Profile).
///
/// Stateless: the selected index lives in the parent ([currentIndex]) and
/// changes are reported through [onTap] — `UI = f(state)`.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: AppShadows.bar),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: ColoredBox(
            color: AppColors.barBackground,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: AppSizes.tabBarHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: Row(
                    children: [
                      for (final (int index, AppNavItem item) in items.indexed)
                        Expanded(
                          child: _NavButton(
                            item: item,
                            selected: index == currentIndex,
                            onTap: () => onTap(index),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.primary : AppColors.textTertiary;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: AppSpacing.minTapTarget,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(item.icon, color: color),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                item.label,
                style: AppTextStyles.tabLabel.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
