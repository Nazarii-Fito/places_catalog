import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/auth_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../data/mock/mock_user.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/place.dart';
import '../widgets/activity_summary_card.dart';
import '../widgets/connected_accounts_group.dart';
import '../widgets/log_out_button.dart';
import '../widgets/profile_hero.dart';
import '../widgets/version_footer.dart';

/// Profile tab (FR2): Firebase user data, statistics (still a mock),
/// password change, connected accounts, archive export and log-out.
///
/// Name, e-mail, photo and linked providers come from
/// `AuthRepository.userChanges()`, so edits from Edit Profile or a new
/// Google link appear immediately.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.places});

  /// Current catalog — the source of the JSON export.
  final List<Place> places;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Stream<AppUser?>? _user;
  bool _linkingGoogle = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Created once (not in build) so the StreamBuilder keeps its listener.
    _user ??= AppScope.of(context).auth.userChanges();
  }

  void _openChangePassword(AppUser user) {
    if (!user.hasPassword) {
      // Google-only account: there is no password to re-authenticate with.
      AppConfirmDialog.show(
        context,
        title: AppStrings.noPasswordTitle,
        message: AppStrings.noPasswordMessage,
        confirmLabel: AppStrings.ok,
        cancelLabel: null,
      );
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.changePassword);
  }

  Future<void> _linkGoogle() async {
    if (_linkingGoogle) return;
    final AppScope scope = AppScope.of(context);
    setState(() => _linkingGoogle = true);
    try {
      final bool linked = await scope.auth.linkGoogle();
      if (linked) await scope.analytics.logAccountLinked('google.com');
    } on AuthFailure catch (failure) {
      if (mounted) {
        await AppConfirmDialog.show(
          context,
          title: AppStrings.linkFailedTitle,
          message: failure.message,
          confirmLabel: AppStrings.ok,
          cancelLabel: null,
        );
      }
    } finally {
      if (mounted) setState(() => _linkingGoogle = false);
    }
  }

  Future<void> _confirmLogOut() async {
    final AppScope scope = AppScope.of(context);
    final bool confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.logOutDialogTitle,
      message: AppStrings.logOutDialogMessage,
      confirmLabel: AppStrings.logOut,
      isDestructive: true,
    );
    if (!confirmed) return;
    // AuthGate notices the signed-out state and shows Login.
    try {
      await scope.auth.signOut();
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      await AppConfirmDialog.show(
        context,
        title: AppStrings.logOut,
        message: failure.message,
        confirmLabel: AppStrings.ok,
        cancelLabel: null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavHeader(title: AppStrings.tabProfile),
      body: StreamBuilder<AppUser?>(
        stream: _user,
        initialData: AppScope.of(context).auth.currentUser,
        builder: (BuildContext context, AsyncSnapshot<AppUser?> snapshot) {
          final AppUser? user = snapshot.data;
          // Signed out: AuthGate is about to replace this screen.
          if (user == null) return const SizedBox.shrink();
          final EdgeInsets insets = MediaQuery.paddingOf(context);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              insets.top,
              AppSpacing.screen,
              insets.bottom + AppSpacing.sm,
            ),
            children: [
              ProfileHero(
                name: user.name,
                email: user.email ?? '',
                photoUrl: user.photoUrl,
                initials: user.initials,
                onEdit: () =>
                    Navigator.of(context).pushNamed(AppRoutes.editProfile),
              ),
              const SizedBox(height: AppSpacing.l),
              // Visit statistics stay a mock until places live in Firestore.
              ActivitySummaryCard(stats: mockUser.stats),
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
                    onTap: () => _openChangePassword(user),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              const SectionLabel(AppStrings.connectedAccounts),
              const SizedBox(height: AppSpacing.s),
              ConnectedAccountsGroup(
                user: user,
                linkingGoogle: _linkingGoogle,
                onLinkGoogle: _linkGoogle,
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
              const SizedBox(height: AppSpacing.sm),
              const VersionFooter(),
            ],
          );
        },
      ),
    );
  }
}
