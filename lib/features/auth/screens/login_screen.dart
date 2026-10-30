import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/app_scope.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/auth_failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_text_link.dart';
import '../../../core/widgets/divider_with_text.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/social_auth_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_legal_text.dart';
import '../widgets/auth_page.dart';
import '../widgets/social_auth_row.dart';
import '../widgets/social_sign_in.dart';

/// Sign-in screen (FR1): e-mail/password via `AuthRepository`, Google with
/// account linking, Sign in with Apple.
///
/// After a successful sign-in nothing is pushed here — `AuthGate` sees the
/// new user and shows the main shell (that also covers session restore).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Created once per State — never in build(), or every rebuild would
  // create a new form and lose the field state.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return; // a second tap must not send a second request
    FocusScope.of(context).unfocus();
    // After the first attempt, fields re-validate while the user types.
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final AppScope scope = AppScope.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await scope.auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await scope.analytics.logLogin('password');
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _social(SocialProvider provider) async {
    if (_submitting) return;
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
    // Gaps are tighter than in Figma so the whole form fits an iPhone 17
    // screen without scrolling (see docs/decisions.md).
    return AuthPage(
      form: [
        const SizedBox(height: AppSpacing.m),
        const AuthHeader(
          title: AppStrings.appName,
          subtitle: TextSpan(text: AppStrings.tagline),
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: AppSpacing.l),
              AppTextField(
                label: AppStrings.passwordLabel,
                hintText: AppStrings.passwordHint,
                prefixIcon: AppAssets.iconLock,
                controller: _passwordController,
                isPassword: true,
                readOnly: _submitting,
                // Sign-in only checks presence; the policy applies to new
                // passwords. Whether it is correct is Firebase's answer.
                validator: Validators.required,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.password],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: Align(
            alignment: Alignment.centerRight,
            child: AppTextLink(
              label: AppStrings.forgotPassword,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
            ),
          ),
        ),
        if (error != null) ...[
          ErrorBanner(message: error),
          const SizedBox(height: AppSpacing.m),
        ] else
          const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          label: AppStrings.logIn,
          isLoading: _submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.m),
        SecondaryButton(
          label: AppStrings.createAccount,
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pushNamed(AppRoutes.register),
        ),
        const SizedBox(height: 20),
        const DividerWithText(text: AppStrings.orContinueWith),
        const SizedBox(height: 20),
        SocialAuthRow(onProviderSelected: _social),
      ],
      // Pinned to the bottom edge of the screen.
      footer: const [
        SizedBox(height: AppSpacing.l),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: AuthLegalText(prefix: AppStrings.loginLegalPrefix),
        ),
        SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
