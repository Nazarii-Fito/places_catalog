import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/analytics_service.dart';
import '../../../app/routes/app_routes.dart';
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
import '../../session/bloc/auth_bloc.dart';
import '../bloc/change_password_cubit.dart';

/// Change password (requirement 3.2 / Lab 4 4b): re-authenticates with the
/// current password, then updates it in Firebase. A wrong current password
/// is shown under its field; `requires-recent-login` asks to log in again.
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChangePasswordCubit>(
      create: (BuildContext context) => ChangePasswordCubit(
        auth: context.read<AuthRepository>(),
        analytics: context.read<AnalyticsService>(),
      ),
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView();

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _updatePassword() {
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    // The cubit drops a repeated request while one is running.
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ChangePasswordCubit>().submit(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
  }

  /// Side effects of a finished request. They run when the state has
  /// already left `submitting`, so the spinner never keeps turning behind
  /// a dialog.
  Future<void> _onResult(
    BuildContext context,
    ChangePasswordState state,
  ) async {
    final ChangePasswordCubit cubit = context.read<ChangePasswordCubit>();
    final NavigatorState navigator = Navigator.of(context);
    final AuthBloc session = context.read<AuthBloc>();
    if (state.status == ChangePasswordStatus.success) {
      await AppConfirmDialog.show(
        context,
        title: AppStrings.passwordUpdatedTitle,
        message: AppStrings.passwordUpdatedMessage,
        confirmLabel: AppStrings.ok,
        cancelLabel: null,
      );
      navigator.pop();
    } else if (state.failureType == AuthFailureType.requiresRecentLogin) {
      // The session is too old for a sensitive change: explain, offer to
      // log out and back in.
      final bool signOut = await AppConfirmDialog.show(
        context,
        title: AppStrings.signInAgainTitle,
        message: AppStrings.errorRecentLogin,
        confirmLabel: AppStrings.logOut,
      );
      cubit.clearError();
      if (signOut) session.add(const AuthLogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChangePasswordState state = context
        .watch<ChangePasswordCubit>()
        .state;
    final bool submitting = state.status == ChangePasswordStatus.submitting;
    final bool failed = state.status == ChangePasswordStatus.failure;
    // Where an error goes depends on its kind.
    final String? currentPasswordError =
        failed && state.failureType == AuthFailureType.invalidCredentials
        ? state.message
        : null;
    final String? error =
        failed &&
            state.failureType != AuthFailureType.invalidCredentials &&
            state.failureType != AuthFailureType.requiresRecentLogin
        ? state.message
        : null;
    return BlocListener<ChangePasswordCubit, ChangePasswordState>(
      listenWhen: (before, now) => before.status != now.status,
      listener: _onResult,
      child: Scaffold(
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
                      readOnly: submitting,
                      validator: Validators.required,
                      errorText: currentPasswordError,
                      onChanged: (_) =>
                          context.read<ChangePasswordCubit>().clearError(),
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
                      readOnly: submitting,
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
                      readOnly: submitting,
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
                      isLoading: submitting,
                      onPressed: _updatePassword,
                    ),
                  ],
                ),
              );
            },
          ),
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
