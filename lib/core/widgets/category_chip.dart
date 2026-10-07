import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Filter pill. Selected — filled blue; unselected — grey.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // Full row height (40 pt) is tappable, not only the 32 pt pill.
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: AppSizes.chipHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surfaceContainer,
              borderRadius: AppRadii.pillAll,
              boxShadow: selected ? AppShadows.subtle : null,
            ),
            child: Text(
              label,
              style: selected
                  ? AppTextStyles.footnoteSemibold.copyWith(
                      color: AppColors.onPrimary,
                    )
                  : AppTextStyles.footnoteMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
