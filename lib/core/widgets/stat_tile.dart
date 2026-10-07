import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_svg_icon.dart';

/// Small statistics tile on the profile: icon, number, caption.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  /// SVG asset path (keeps its own Figma colour).
  final String icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.smAll,
      ),
      child: Column(
        children: [
          SizedBox(height: 16.667, child: Center(child: AppSvgIcon(icon))),
          const SizedBox(height: AppSpacing.xxs + AppSpacing.xs),
          Text('$value', style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: AppTextStyles.tabLabel.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
