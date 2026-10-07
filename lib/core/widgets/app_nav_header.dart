import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_logo.dart';

/// Translucent top header of in-app screens (56 pt + status bar).
///
/// Variants are built from optional parts:
/// * `AppNavHeader(title: 'Home')` — logo + title (tab roots);
/// * `AppNavHeader(leading: NavBackButton(label: 'Profile'))` — back only;
/// * `AppNavHeader(leading: NavBackButton(), title: 'Add Place')` —
///   chevron + logo + title (pushed screens).
///
/// Implements [PreferredSizeWidget] so it can be passed to
/// `Scaffold.appBar` together with `extendBodyBehindAppBar: true`; the
/// content then scrolls under the blurred background like on iOS.
class AppNavHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppNavHeader({super.key, this.title, this.leading, this.trailing});

  final String? title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.headerHeight);

  @override
  Widget build(BuildContext context) {
    final String? text = title;
    final Widget? lead = leading;
    final Widget? trail = trailing;
    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: AppShadows.bar),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: ColoredBox(
            color: AppColors.barBackground,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: AppSizes.headerHeight,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: lead == null ? AppSpacing.l : AppSpacing.sm,
                    right: AppSpacing.l,
                  ),
                  child: Row(
                    children: [
                      ?lead,
                      if (lead != null && text != null)
                        const SizedBox(width: AppSpacing.sm),
                      if (text != null) ...[
                        const AppLogo.small(),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            text,
                            style: AppTextStyles.headline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (trail != null) ...[const Spacer(), trail],
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
