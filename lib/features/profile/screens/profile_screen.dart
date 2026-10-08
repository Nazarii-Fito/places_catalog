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
import '../../../data/models/place.dart';
import '../../../data/models/user.dart';
import '../widgets/activity_summary_card.dart';
import '../widgets/log_out_button.dart';
import '../widgets/profile_hero.dart';

/// Profile tab (FR2): user data, statistics, password change, archive
/// export and log-out.
///
/// Starts from the hardcoded [mockUser]; the edited copy returned by
/// Edit Profile is kept in this screen's state.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.places});

  /// Current catalog — the source of the JSON export.
  final List<Place> places;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User _user = mockUser;

  Future<void> _editProfile() async {
    final Object? result = await Navigator.of(context)
        .pushNamed(AppRoutes.editProfile, arguments: _user);
    if (result is User) setState(() => _user = result);
  }

  Future<void> _confirmLogOut() async {
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

  @override
  Widget build(BuildContext context) {
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
                name: _user.fullName,
                email: _user.email,
                avatarAsset: _user.avatarAsset,
                initials: _user.initials,
                onEdit: _editProfile,
              ),
              const SizedBox(height: AppSpacing.l),
              ActivitySummaryCard(stats: _user.stats),
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
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              const SectionLabel(AppStrings.dataAndPrivacy),
              const SizedBox(height: AppSpacing.s),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: const AppSvgIcon(AppAssets.iconDownload),
                    title: AppStrings.exportArchive,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.exportArchive,
                      arguments: widget.places,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l + AppSpacing.xs),
              LogOutButton(onPressed: _confirmLogOut),
            ],
          );
        },
      ),
    );
  }
}
