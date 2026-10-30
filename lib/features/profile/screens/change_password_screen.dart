import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/app_scope.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/auth_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_nav_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/app_text_link.dart';
import '../../../core/widgets/nav_back_button.dart';
import '../../../core/widgets/primary_button.dart';

/// Change password (requirement 3.2 / Lab 4 4b): re-authenticates with the
/// current password, then updates it in Firebase. A wrong current password
/// is shown under its field; `requires-recent-login` asks to log in again.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _submitting = false;

  /// Firebase rejected the current password — shown under that field.
  String? _currentPasswordError;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _autovalidate = AutovalidateMode.onUserInteraction;
      _currentPasswordError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final AppScope scope = AppScope.of(context);
    final NavigatorState navigator = Navigator.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    bool needsSignIn = false;
    bool changed = false;
    try {
      // Re-authenticates with the current password, then updates it.
      await scope.auth.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      await scope.analytics.logPasswordChanged();
      changed = true;
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      switch (failure.type) {
        case AuthFailureType.invalidCredentials:
          setState(() => _currentPasswordError = failure.message);
        case AuthFailureType.requiresRecentLogin:
          needsSignIn = true;
        default:
          setState(() => _error = failure.message);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    // Dialogs are shown after the spinner stops, so it doesn't keep
    // spinning behind them.
    if (!mounted) return;
    if (changed) {
      await AppConfirmDialog.show(
        context,
        title: AppStrings.passwordUpdatedTitle,
        message: AppStrings.passwordUpdatedMessage,
        confirmLabel: AppStrings.ok,
        cancelLabel: null,
      );
      navigator.pop();
    } else if (needsSignIn) {
      await _askToSignInAgain(scope);
    }
  }

  /// `requires-recent-login`: the session is too old for a sensitive
  /// change. Explain it and offer to log out and back in.
  Future<void> _askToSignInAgain(AppScope scope) async {
    final bool signOut = await AppConfirmDialog.show(
      context,
      title: AppStrings.signInAgainTitle,
      message: AppStrings.errorRecentLogin,
      confirmLabel: AppStrings.logOut,
    );
    if (signOut) await scope.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final String? error = _error;
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
            return Form(
              key: _formKey,
              autovalidateMode: _autovalidate,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                    readOnly: _submitting,
                    validator: Validators.required,
                    errorText: _currentPasswordError,
                    onChanged: (_) {
                      if (_currentPasswordError != null) {
                        setState(() => _currentPasswordError = null);
                      }
                    },
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
                    readOnly: _submitting,
                    helperText: AppStrings.passwordHelper,
                    validator: Validators.newPasswordDifferentFrom(
                      () => _currentController.text,
                    ),
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
                    readOnly: _submitting,
                    validator: Validators.matches(() => _newController.text),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _updatePassword(),
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: AppSpacing.l + AppSpacing.sm),
                  if (error != null) ...[
                    ErrorBanner(message: error),
                    const SizedBox(height: AppSpacing.m),
                  ],
                  PrimaryButton(
                    label: AppStrings.updatePassword,
                    isLoading: _submitting,
                    onPressed: _updatePassword,
                  ),
                ],
              ),
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
