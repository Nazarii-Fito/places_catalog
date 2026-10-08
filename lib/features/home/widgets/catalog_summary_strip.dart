import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/pressable_opacity.dart';
import '../home_sort.dart';

/// "■ 24 recorded spots · Sorted by Recent ⇅" strip; the right part opens
/// a pull-down menu with the sort orders.
class CatalogSummaryStrip extends StatelessWidget {
  const CatalogSummaryStrip({
    super.key,
    required this.count,
    required this.sort,
    required this.onSortSelected,
  });

  final int count;
  final HomeSort sort;
  final ValueChanged<HomeSort> onSortSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.m),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.mdAll,
      ),
      child: Row(
        children: [
          const AppSvgIcon(AppAssets.iconBookmark),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$count',
                children: [
                  TextSpan(
                    text: AppStrings.recordedSpots,
                    style: AppTextStyles.footnoteMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              style: AppTextStyles.footnoteSemibold,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _SortMenu(sort: sort, onSelected: onSortSelected),
        ],
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onSelected});

  final HomeSort sort;
  final ValueChanged<HomeSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, AppSpacing.xs),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.surface),
        surfaceTintColor: WidgetStatePropertyAll(AppColors.transparent),
        elevation: WidgetStatePropertyAll(8),
        shadowColor: WidgetStatePropertyAll(AppColors.shadow10),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
        ),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: AppSpacing.xs),
        ),
      ),
      menuChildren: HomeSort.values
          .map(
            (HomeSort option) => MenuItemButton(
              onPressed: () => onSelected(option),
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size(200, 44)),
                overlayColor: WidgetStatePropertyAll(
                  AppColors.surfaceContainer,
                ),
              ),
              leadingIcon: SizedBox(
                width: 20,
                child: option == sort
                    ? const Icon(
                        CupertinoIcons.checkmark_alt,
                        size: 18,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              child: Text(option.label, style: AppTextStyles.body),
            ),
          )
          .toList(),
      builder: (BuildContext context, MenuController controller, _) {
        return Semantics(
          button: true,
          child: PressableOpacity(
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
            // 34 pt strip + taller hit area to the right edge.
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.m,
                AppSpacing.sm,
              ),
              child: Row(
                spacing: AppSpacing.s,
                children: [
                  Text(
                    AppStrings.sortedByPrefix + sort.label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const AppSvgIcon(AppAssets.iconSort),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
