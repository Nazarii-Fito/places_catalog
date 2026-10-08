import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/divider_with_text.dart';
import '../../../core/widgets/nav_back_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/social_auth_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_legal_text.dart';
import '../widgets/auth_page.dart';
import '../widgets/auth_switch_prompt.dart';
import '../widgets/social_auth_row.dart';

/// Sign-up screen (FR1). "Create Account" opens Home without validation.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openHome() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
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
        AppTextField(
          label: AppStrings.fullNameLabel,
          hintText: AppStrings.fullNameHint,
          prefixIcon: AppAssets.iconPerson,
          controller: _nameController,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
        ),
        const SizedBox(height: 10),
        AppTextField(
          label: AppStrings.emailLabel,
          hintText: AppStrings.emailHint,
          prefixIcon: AppAssets.iconMail,
          controller: _emailController,
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
          helperText: AppStrings.passwordHelper,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _openHome(),
          autofillHints: const [AutofillHints.newPassword],
        ),
        const SizedBox(height: AppSpacing.l),
        PrimaryButton(label: AppStrings.createAccount, onPressed: _openHome),
        const SizedBox(height: AppSpacing.ml),
        const DividerWithText(text: AppStrings.orContinueWith),
        const SizedBox(height: AppSpacing.ml),
        SocialAuthRow(onProviderSelected: (SocialProvider _) => _openHome()),
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
