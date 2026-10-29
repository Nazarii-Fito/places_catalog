import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/auth_failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/divider_with_text.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/nav_back_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/social_auth_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_legal_text.dart';
import '../widgets/auth_page.dart';
import '../widgets/auth_switch_prompt.dart';
import '../widgets/social_auth_row.dart';
import '../widgets/social_sign_in.dart';

/// Sign-up screen (FR1): creates a Firebase account with the full name.
///
/// The [Form] validates name, e-mail and password locally first; only a
/// valid form reaches `AuthRepository.signUp`. Firebase errors (e.g. the
/// e-mail is taken) appear in the [ErrorBanner].
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final AppScope scope = AppScope.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await scope.auth.signUp(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await scope.analytics.logSignUp('password');
      // AuthGate now shows the main shell and pops this screen.
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _social(SocialProvider provider) async {
    if (_submitting) return;
    // Apple only shows an info dialog: no request, so no loading state.
    if (provider == SocialProvider.apple) {
      await runSocialSignIn(context, provider);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final String? error = await runSocialSignIn(context, provider);
    if (mounted) {
      setState(() {
        _submitting = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? error = _error;
    // Gaps are tighter than in Figma so the form fits an iPhone 17 screen
    // without scrolling (see docs/decisions.md).
    return AuthPage(
      form: [
        // "‹ Log In": the chevron lines up with the 16 pt margin.
        Transform.translate(
          offset: const Offset(-AppSpacing.sm, 0),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: NavBackButton(label: AppStrings.logIn),
          ),
        ),
        const AuthHeader(
          title: AppStrings.createAccount,
          subtitle: TextSpan(text: AppStrings.registerSubtitle),
          iconGap: AppSpacing.l,
        ),
        const SizedBox(height: AppSpacing.l),
        Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: AppStrings.fullNameLabel,
                hintText: AppStrings.fullNameHint,
                prefixIcon: AppAssets.iconPerson,
                controller: _nameController,
                readOnly: _submitting,
                validator: Validators.fullName,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: 10),
              AppTextField(
                label: AppStrings.emailLabel,
                hintText: AppStrings.emailHint,
                prefixIcon: AppAssets.iconMail,
                controller: _emailController,
                readOnly: _submitting,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 10),
              AppTextField(
                label: AppStrings.passwordLabel,
                hintText: AppStrings.passwordHint,
                prefixIcon: AppAssets.iconLock,
                controller: _passwordController,
                isPassword: true,
                readOnly: _submitting,
                helperText: AppStrings.passwordHelper,
                validator: Validators.newPassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.newPassword],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        if (error != null) ...[
          ErrorBanner(message: error),
          const SizedBox(height: AppSpacing.m),
        ],
        PrimaryButton(
          label: AppStrings.createAccount,
          isLoading: _submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.ml),
        const DividerWithText(text: AppStrings.orContinueWith),
        const SizedBox(height: AppSpacing.ml),
        SocialAuthRow(onProviderSelected: _social),
      ],
      // Pinned to the bottom edge of the screen.
      footer: [
        const SizedBox(height: AppSpacing.l),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: AuthLegalText(prefix: AppStrings.registerLegalPrefix),
        ),
        AuthSwitchPrompt(
          question: AppStrings.alreadyHaveAccount,
          actionLabel: AppStrings.logIn,
          onAction: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
