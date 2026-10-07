import 'package:flutter/widgets.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_svg_icon.dart';
import 'pressable_opacity.dart';

/// iOS back button: chevron + title of the previous screen ("‹ Log In").
///
/// iPhone has no system Back key, so every pushed screen shows this button;
/// by default it pops the current route.
class NavBackButton extends StatelessWidget {
  const NavBackButton({super.key, this.label, this.onPressed});

  /// Title of the previous screen; `null` shows the chevron only.
  final String? label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final String? text = label;
    return Semantics(
      button: true,
      label: text,
      child: PressableOpacity(
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTapTarget,
            minWidth: AppSpacing.minTapTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            // Without a label the chevron is centred in the 44 pt square.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppSvgIcon(AppAssets.iconChevronLeft),
                if (text != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: AppTextStyles.subheadline.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
