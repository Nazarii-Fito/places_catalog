import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_text_link.dart';
import '../../../core/widgets/divider_with_text.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/social_auth_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_legal_text.dart';
import '../widgets/social_auth_row.dart';

/// Sign-in screen (FR1). No business logic: "Log In" and the social
/// buttons simply open Home.
///
/// Stateful only to own the text controllers (created once, disposed with
/// the screen). Password visibility is local state of [AppTextField].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Home becomes the only route: "Back" must not return to Login.
  void _openHome() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // Tap on empty space hides the keyboard.
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xxl,
              AppSpacing.screen,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(
                  title: AppStrings.appName,
                  subtitle: TextSpan(text: AppStrings.tagline),
                ),
                const SizedBox(height: 40.5),
                AppTextField(
                  label: AppStrings.emailLabel,
                  hintText: AppStrings.emailHint,
                  prefixIcon: AppAssets.iconMail,
                  controller: _emailController,
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
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _openHome(),
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(height: AppSpacing.l + AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AppTextLink(
                      label: AppStrings.forgotPassword,
                      onTap: () =>
                          Navigator.of(context)
                              .pushNamed(AppRoutes.forgotPassword),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l + AppSpacing.sm),
                PrimaryButton(label: AppStrings.logIn, onPressed: _openHome),
                const SizedBox(height: AppSpacing.m),
                SecondaryButton(
                  label: AppStrings.createAccount,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.register),
                ),
                const SizedBox(height: AppSpacing.xl),
                const DividerWithText(text: AppStrings.orContinueWith),
                const SizedBox(height: AppSpacing.xl),
                SocialAuthRow(
                  onProviderSelected: (SocialProvider _) => _openHome(),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: AuthLegalText(prefix: AppStrings.loginLegalPrefix),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
