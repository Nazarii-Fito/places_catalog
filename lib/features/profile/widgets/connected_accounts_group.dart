import 'package:flutter/cupertino.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../data/models/app_user.dart';

/// "Connected Accounts": which sign-in methods are linked to this one
/// Firebase account (read from `providerData`), with "Link" for Google.
class ConnectedAccountsGroup extends StatelessWidget {
  const ConnectedAccountsGroup({
    super.key,
    required this.user,
    required this.linkingGoogle,
    required this.onLinkGoogle,
  });

  final AppUser user;
  final bool linkingGoogle;
  final VoidCallback onLinkGoogle;

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      children: [
        SettingsTile(
          icon: const AppSvgIcon(
            AppAssets.iconMail,
            color: AppColors.textPrimary,
          ),
          title: AppStrings.providerEmail,
          value: user.hasPassword ? AppStrings.linked : AppStrings.notSet,
          showChevron: false,
          onTap: () {},
        ),
        SettingsTile(
          icon: const AppSvgIcon(AppAssets.iconGoogle, width: 16, height: 16),
          title: AppStrings.providerGoogle,
          value: user.hasGoogle ? AppStrings.linked : null,
          showChevron: false,
          onTap: user.hasGoogle || linkingGoogle ? () {} : onLinkGoogle,
          trailing: user.hasGoogle
              ? null
              : linkingGoogle
              ? const CupertinoActivityIndicator()
              : Text(
                  AppStrings.link,
                  style: AppTextStyles.socialLabel.copyWith(
                    color: AppColors.primary,
                  ),
                ),
        ),
      ],
    );
  }
}
