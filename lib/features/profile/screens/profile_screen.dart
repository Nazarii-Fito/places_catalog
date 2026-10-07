import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../data/mock/mock_user.dart';
import '../../../data/models/user.dart';
import '../widgets/activity_summary_card.dart';
import '../widgets/log_out_button.dart';
import '../widgets/profile_hero.dart';

/// Profile tab (FR2): user data, statistics, settings and log-out.
///
/// Stateless — everything comes from the hardcoded [mockUser]; the only
/// interaction with a result is the log-out confirmation.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogOut(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final bool confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.logOutDialogTitle,
      message: AppStrings.logOutDialogMessage,
      confirmLabel: AppStrings.logOut,
      isDestructive: true,
    );
    if (!confirmed) return;
    navigator.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (Route<dynamic> route) => false,
    );
  }

  // App Settings, iCloud sync, export and photo editing have no screens in
  // Lab 3 (no business logic) — these rows are intentionally inert.
  static void _notImplemented() {}

  @override
  Widget build(BuildContext context) {
    final User user = mockUser;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavHeader(title: AppStrings.tabProfile),
      body: Builder(
        builder: (BuildContext context) {
          final EdgeInsets insets = MediaQuery.paddingOf(context);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              insets.top,
              AppSpacing.screen,
              insets.bottom + AppSpacing.xl,
            ),
            children: [
              ProfileHero(
                name: user.fullName,
                email: user.email,
                avatarAsset: user.avatarAsset,
                onEditPhoto: _notImplemented,
              ),
              const SizedBox(height: AppSpacing.l),
              ActivitySummaryCard(stats: user.stats),
              const SizedBox(height: AppSpacing.l),
              const SectionLabel(AppStrings.accountSettings),
              const SizedBox(height: AppSpacing.s),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: const AppSvgIcon(
                      AppAssets.iconLock,
                      height: 14,
                      color: AppColors.textPrimary,
                    ),
                    title: AppStrings.changePassword,
                    onTap: () =>
                        Navigator.of(context)
                            .pushNamed(AppRoutes.changePassword),
                  ),
                  const SettingsTile(
                    icon: Icon(
                      Icons.settings_outlined,
                      size: 17,
                      color: AppColors.textPrimary,
                    ),
                    title: AppStrings.appSettings,
                    onTap: _notImplemented,
                  ),
                  const SettingsTile(
                    icon: Icon(
                      Icons.cloud_outlined,
                      size: 17,
                      color: AppColors.textPrimary,
                    ),
                    title: AppStrings.icloudSync,
                    badge: AppStrings.active,
                    onTap: _notImplemented,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              const SectionLabel(AppStrings.dataAndPrivacy),
              const SizedBox(height: AppSpacing.s),
              const SettingsGroup(
                children: [
                  SettingsTile(
                    icon: AppSvgIcon(AppAssets.iconDownload),
                    title: AppStrings.exportArchive,
                    onTap: _notImplemented,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l + AppSpacing.xs),
              LogOutButton(onPressed: () => _confirmLogOut(context)),
            ],
          );
        },
      ),
    );
  }
}
