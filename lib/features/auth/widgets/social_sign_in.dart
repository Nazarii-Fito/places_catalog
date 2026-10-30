import 'package:flutter/cupertino.dart';

import '../../../app/app_scope.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/auth_failure.dart';
import '../../../core/widgets/social_auth_button.dart';

/// Runs the chosen social sign-in from Login / Create Account.
///
/// Returns an error message for the banner, or `null` on success or
/// cancel.
Future<String?> runSocialSignIn(
  BuildContext context,
  SocialProvider provider,
) async {
  switch (provider) {
    case SocialProvider.apple:
      return _runApple(context);
    case SocialProvider.google:
      return _runGoogle(context);
  }
}

Future<String?> _runApple(BuildContext context) async {
  final AppScope scope = AppScope.of(context);
  try {
    final bool signedIn = await scope.auth.signInWithApple();
    if (signedIn) await scope.analytics.logLogin('apple');
    return null;
  } on AuthFailure catch (failure) {
    return failure.message;
  }
}

Future<String?> _runGoogle(BuildContext context) async {
  final AppScope scope = AppScope.of(context);
  try {
    final bool signedIn = await scope.auth.signInWithGoogle();
    if (signedIn) await scope.analytics.logLogin('google');
    return null;
  } on AuthFailure catch (failure) {
    final String? email = failure.email;
    if (failure.type != AuthFailureType.accountExistsWithDifferentCredential ||
        email == null) {
      return failure.message;
    }
    // Same e-mail already has a password account: confirm the password,
    // then link Google to it — one account, two sign-in methods.
    if (!context.mounted) return null;
    final String? password = await showCupertinoDialog<String>(
      context: context,
      builder: (_) => _LinkPasswordDialog(email: email),
    );
    if (password == null || password.isEmpty) return null;
    try {
      await scope.auth.completeGoogleLink(email: email, password: password);
      await scope.analytics.logAccountLinked('google.com');
      return null;
    } on AuthFailure catch (linkFailure) {
      return linkFailure.message;
    }
  }
}

class _LinkPasswordDialog extends StatefulWidget {
  const _LinkPasswordDialog({required this.email});

  final String email;

  @override
  State<_LinkPasswordDialog> createState() => _LinkPasswordDialogState();
}

class _LinkPasswordDialogState extends State<_LinkPasswordDialog> {
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_password.text);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(AppStrings.linkGoogleTitle),
      content: Column(
        children: [
          Text('${AppStrings.linkGoogleMessage}\n${widget.email}'),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _password,
            autofocus: true,
            obscureText: true,
            placeholder: AppStrings.passwordLabel,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _submit,
          child: const Text(AppStrings.connect),
        ),
      ],
    );
  }
}
