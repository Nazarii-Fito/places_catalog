import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/analytics_service.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/divider_with_text.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/nav_back_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/social_auth_button.dart';
import '../bloc/login_bloc.dart';
import '../bloc/register_bloc.dart';
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
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Two blocs: `RegisterBloc` for the form, and `LoginBloc` because the
    // Google/Apple buttons on this screen sign in through it.
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegisterBloc>(
          create: (BuildContext context) => RegisterBloc(
            auth: context.read<AuthRepository>(),
            analytics: context.read<AnalyticsService>(),
          ),
        ),
        BlocProvider<LoginBloc>(
          create: (BuildContext context) => LoginBloc(
            auth: context.read<AuthRepository>(),
            analytics: context.read<AnalyticsService>(),
          ),
        ),
      ],
      child: const LoginLinkListener(child: _RegisterView()),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<RegisterBloc>().add(
      RegisterSubmitted(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RegisterState register = context.watch<RegisterBloc>().state;
    final LoginState login = context.watch<LoginBloc>().state;
    // One "busy" flag for both flows, so neither can start while the other
    // is running.
    final bool submitting =
        register is RegisterLoading || login is LoginLoading;
    final String? error = switch ((register, login)) {
      (RegisterFailure(:final message), _) => message,
      (_, LoginFailure(:final message)) => message,
      _ => null,
    };
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
                readOnly: submitting,
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
                readOnly: submitting,
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
                readOnly: submitting,
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
          isLoading: submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.ml),
        const DividerWithText(text: AppStrings.orContinueWith),
        const SizedBox(height: AppSpacing.ml),
        SocialAuthRow(
          onProviderSelected: submitting
              ? (_) {}
              : (SocialProvider p) => startSocialSignIn(context, p),
        ),
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
