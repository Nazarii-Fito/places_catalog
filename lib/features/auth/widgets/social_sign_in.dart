import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/social_auth_button.dart';
import '../bloc/login_bloc.dart';

/// Sends the tapped provider to `LoginBloc` (used by Login *and* Register,
/// which both show the same Google/Apple buttons).
void startSocialSignIn(BuildContext context, SocialProvider provider) {
  final LoginBloc bloc = context.read<LoginBloc>();
  switch (provider) {
    case SocialProvider.apple:
      bloc.add(const LoginAppleRequested());
    case SocialProvider.google:
      bloc.add(const LoginGoogleRequested());
  }
}

/// Reacts to `LoginLinkRequired`: Google's e-mail already has a password
/// account, so ask for that password and let the bloc link Google to it —
/// one account, two sign-in methods. A dialog is a side effect, which is
/// exactly what `BlocListener` is for (not `BlocBuilder`).
class LoginLinkListener extends StatelessWidget {
  const LoginLinkListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (_, LoginState now) => now is LoginLinkRequired,
      listener: (BuildContext context, LoginState state) async {
        final String email = (state as LoginLinkRequired).email;
        final LoginBloc bloc = context.read<LoginBloc>();
        final String? password = await showCupertinoDialog<String>(
          context: context,
          builder: (_) => _LinkPasswordDialog(email: email),
        );
        if (password == null || password.isEmpty) {
          bloc.add(const LoginGoogleLinkCancelled());
        } else {
          bloc.add(LoginGoogleLinkConfirmed(email: email, password: password));
        }
      },
      child: child,
    );
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
