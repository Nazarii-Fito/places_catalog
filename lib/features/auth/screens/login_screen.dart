import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/analytics_service.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_text_link.dart';
import '../../../core/widgets/divider_with_text.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/social_auth_button.dart';
import '../bloc/login_bloc.dart';
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
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The bloc lives exactly as long as this screen.
    return BlocProvider<LoginBloc>(
      create: (BuildContext context) => LoginBloc(
        auth: context.read<AuthRepository>(),
        analytics: context.read<AnalyticsService>(),
      ),
      child: const LoginLinkListener(child: _LoginView()),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  // Created once per State — never in build(), or every rebuild would
  // create a new form and lose the field state.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    // After the first attempt, fields re-validate while the user types.
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // A tap during loading is ignored by the bloc itself.
    context.read<LoginBloc>().add(
      LoginSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The state decides what is shown: spinner + read-only fields while
    // loading, a banner on failure.
    final LoginState state = context.watch<LoginBloc>().state;
    final bool submitting = state is LoginLoading;
    final String? error = state is LoginFailure ? state.message : null;
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
                readOnly: submitting,
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
                readOnly: submitting,
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
          isLoading: submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.m),
        SecondaryButton(
          label: AppStrings.createAccount,
          onPressed: submitting
              ? null
              : () => Navigator.of(context).pushNamed(AppRoutes.register),
        ),
        const SizedBox(height: 20),
        const DividerWithText(text: AppStrings.orContinueWith),
        const SizedBox(height: 20),
        SocialAuthRow(
          onProviderSelected: submitting
              ? (_) {}
              : (SocialProvider p) => startSocialSignIn(context, p),
        ),
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
