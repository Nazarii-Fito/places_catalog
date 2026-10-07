import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/nav_back_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_switch_prompt.dart';

/// Password recovery by e-mail (Lab 3, requirement 3.1).
///
/// Two UI states of one [StatefulWidget]: the e-mail form and the
/// "Check your email" confirmation. `setState` flips [_linkSent] and
/// `build` describes the screen for the current value — `UI = f(state)`.
/// Nothing is actually sent.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _linkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendLink() {
    FocusScope.of(context).unfocus();
    setState(() => _linkSent = true);
  }

  void _showForm() => setState(() => _linkSent = false);

  void _backToLogin() => Navigator.of(context).pop();

  /// The typed address, or the design placeholder when the field is empty.
  String get _email {
    final String typed = _emailController.text.trim();
    return typed.isEmpty ? AppStrings.emailHint : typed;
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
                Transform.translate(
                  offset: const Offset(-AppSpacing.sm, 0),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: NavBackButton(label: AppStrings.logIn),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _linkSent
                      ? _SentContent(
                          key: const ValueKey('sent'),
                          email: _email,
                          onBackToLogin: _backToLogin,
                          onResend: _showForm,
                        )
                      : _FormContent(
                          key: const ValueKey('form'),
                          controller: _emailController,
                          onSend: _sendLink,
                          onBackToLogin: _backToLogin,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormContent extends StatelessWidget {
  const _FormContent({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onBackToLogin,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeader(
          title: AppStrings.resetPasswordTitle,
          subtitle: TextSpan(text: AppStrings.resetPasswordSubtitle),
        ),
        const SizedBox(height: 40.5),
        AppTextField(
          label: AppStrings.emailLabel,
          hintText: AppStrings.emailHint,
          prefixIcon: AppAssets.iconMail,
          controller: controller,
          helperText: AppStrings.resetEmailHelper,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => onSend(),
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: AppSpacing.l + AppSpacing.sm),
        PrimaryButton(label: AppStrings.sendResetLink, onPressed: onSend),
        const SizedBox(height: AppSpacing.xl),
        AuthSwitchPrompt(
          question: AppStrings.rememberPassword,
          actionLabel: AppStrings.logIn,
          onAction: onBackToLogin,
        ),
      ],
    );
  }
}

class _SentContent extends StatelessWidget {
  const _SentContent({
    super.key,
    required this.email,
    required this.onBackToLogin,
    required this.onResend,
  });

  final String email;
  final VoidCallback onBackToLogin;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeader(
          title: AppStrings.checkEmailTitle,
          icon: const _MailBadge(),
          subtitle: TextSpan(
            text: '${AppStrings.checkEmailSubtitle}\n',
            children: [
              TextSpan(
                text: email,
                style: AppTextStyles.authSubtitle.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40.5),
        PrimaryButton(label: AppStrings.backToLogIn, onPressed: onBackToLogin),
        const SizedBox(height: AppSpacing.xl),
        AuthSwitchPrompt(
          question: AppStrings.didntGetEmail,
          actionLabel: AppStrings.resend,
          onAction: onResend,
        ),
      ],
    );
  }
}

/// 80 pt tinted circle with the envelope glyph (success state icon).
class _MailBadge extends StatelessWidget {
  const _MailBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primaryTint,
        shape: BoxShape.circle,
      ),
      child: const AppSvgIcon(
        AppAssets.iconMail,
        width: 35,
        height: 28,
        color: AppColors.primary,
      ),
    );
  }
}
