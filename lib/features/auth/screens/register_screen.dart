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
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                ),
                const SizedBox(height: 17),
                AppTextField(
                  label: AppStrings.fullNameLabel,
                  hintText: AppStrings.fullNameHint,
                  prefixIcon: AppAssets.iconPerson,
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: AppSpacing.l),
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
                  helperText: AppStrings.passwordHelper,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _openHome(),
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: AppSpacing.l + AppSpacing.sm),
                PrimaryButton(
                  label: AppStrings.createAccount,
                  onPressed: _openHome,
                ),
                // Register uses a tighter divider block than Login (Figma):
                // line 24 pt below the button, social row 24.75 pt below the
                // line (minus half of the 18 pt caption row).
                const SizedBox(height: 15),
                const DividerWithText(text: AppStrings.orContinueWith),
                const SizedBox(height: 15.75),
                SocialAuthRow(
                  onProviderSelected: (SocialProvider _) => _openHome(),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: AuthLegalText(prefix: AppStrings.registerLegalPrefix),
                ),
                const SizedBox(height: AppSpacing.xl),
                AuthSwitchPrompt(
                  question: AppStrings.alreadyHaveAccount,
                  actionLabel: AppStrings.logIn,
                  onAction: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
