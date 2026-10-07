import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_text_link.dart';
import '../../../core/widgets/nav_back_button.dart';
import '../../../core/widgets/primary_button.dart';

/// Change password (Lab 3, requirement 3.2). No validation or storage:
/// "Update Password" shows a confirmation alert and returns to Profile.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    FocusScope.of(context).unfocus();
    final NavigatorState navigator = Navigator.of(context);
    await AppConfirmDialog.show(
      context,
      title: AppStrings.passwordUpdatedTitle,
      message: AppStrings.passwordUpdatedMessage,
      confirmLabel: AppStrings.ok,
      cancelLabel: null,
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavHeader(
        leading: NavBackButton(label: AppStrings.tabProfile),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Builder(
          builder: (BuildContext context) {
            final EdgeInsets insets = MediaQuery.paddingOf(context);
            return ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screen,
                insets.top + AppSpacing.sm,
                AppSpacing.screen,
                insets.bottom + AppSpacing.xl,
              ),
              children: [
                const _TitleBlock(),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: AppStrings.currentPasswordLabel,
                  hintText: AppStrings.passwordHint,
                  prefixIcon: AppAssets.iconLock,
                  controller: _currentController,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(height: AppSpacing.s),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AppTextLink(
                      label: AppStrings.forgotCurrentPassword,
                      onTap: () =>
                          Navigator.of(context)
                              .pushNamed(AppRoutes.forgotPassword),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                AppTextField(
                  label: AppStrings.newPasswordLabel,
                  hintText: AppStrings.passwordHint,
                  prefixIcon: AppAssets.iconLock,
                  controller: _newController,
                  isPassword: true,
                  helperText: AppStrings.passwordHelper,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: AppSpacing.l),
                AppTextField(
                  label: AppStrings.confirmPasswordLabel,
                  hintText: AppStrings.passwordHint,
                  prefixIcon: AppAssets.iconLock,
                  controller: _confirmController,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _updatePassword(),
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: AppSpacing.l + AppSpacing.sm),
                PrimaryButton(
                  label: AppStrings.updatePassword,
                  onPressed: _updatePassword,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4.5),
        Text(
          AppStrings.accountSecurity.toUpperCase(),
          style: AppTextStyles.overline,
        ),
        const SizedBox(height: 1.5),
        const Text(AppStrings.changePassword, style: AppTextStyles.largeTitle),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.changePasswordSubtitle,
          style: AppTextStyles.subheadline.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
