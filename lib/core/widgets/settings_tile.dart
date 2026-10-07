import 'package:flutter/widgets.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_svg_icon.dart';
import 'pressable_opacity.dart';

/// One row of an iOS inset grouped list: icon tile, title, optional
/// status [badge] and a disclosure chevron.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge,
  });

  /// Icon widget placed inside the grey 32×32 tile.
  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final String? badgeText = badge;
    return Semantics(
      button: true,
      child: PressableOpacity(
        onTap: onTap,
        pressedOpacity: 0.5,
        child: SizedBox(
          height: AppSizes.fieldHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: AppRadii.smAll,
                  ),
                  child: icon,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badgeText != null) ...[
                  _StatusBadge(text: badgeText),
                  const SizedBox(width: AppSpacing.sm),
                ],
                const AppSvgIcon(AppAssets.iconChevronRight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.successTint,
        borderRadius: AppRadii.pillAll,
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// White rounded container that stacks [SettingsTile]s with inset dividers.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  /// Dividers start under the title: 16 padding + 32 icon + 12 gap.
  static const double _dividerInset = AppSpacing.l + 32 + AppSpacing.m;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.mdAll,
        boxShadow: AppShadows.group,
      ),
      child: Column(
        children: [
          for (final (int index, Widget child) in children.indexed) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.only(left: _dividerInset),
                child: SizedBox(
                  height: 0.5,
                  width: double.infinity,
                  child: ColoredBox(color: AppColors.divider),
                ),
              ),
            child,
          ],
        ],
      ),
    );
  }
}
