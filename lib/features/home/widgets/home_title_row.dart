import 'package:flutter/widgets.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/pressable_opacity.dart';

/// "CATALOG & JOURNAL / My Places" large title with the round "+" button.
///
/// HIG: the primary "add" action lives in the header, not in a FAB.
class HomeTitleRow extends StatelessWidget {
  const HomeTitleRow({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.homeOverline.toUpperCase(),
                  style: AppTextStyles.overline,
                ),
                const SizedBox(height: 1.5),
                const Text(
                  AppStrings.myPlaces,
                  style: AppTextStyles.largeTitle,
                ),
              ],
            ),
          ),
        ),
        Semantics(
          button: true,
          label: AppStrings.addPlace,
          child: PressableOpacity(
            onTap: onAdd,
            child: Container(
              width: AppSpacing.minTapTarget,
              height: AppSpacing.minTapTarget,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: AppShadows.elevated,
              ),
              child: const AppSvgIcon(AppAssets.iconPlus),
            ),
          ),
        ),
      ],
    );
  }
}
