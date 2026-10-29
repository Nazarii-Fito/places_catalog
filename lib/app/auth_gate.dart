import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/app_logo.dart';
import '../data/models/app_user.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/shell/main_shell.dart';
import 'app_scope.dart';

/// Root of the app: shows Login or [MainShell] depending on Firebase Auth.
///
/// * UI = f(auth state): a [StreamBuilder] on `authStateChanges()`.
///   Firebase keeps the session on the device, so after a restart a
///   signed-in user goes straight to [MainShell] — session restore.
/// * Side effects (clearing pushed auth screens, analytics / crash user id)
///   run in a separate subscription, never inside `build()`.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Stream<AppUser?>? _authState;
  StreamSubscription<AppUser?>? _sideEffects;
  String? _lastUid;
  bool _firstEvent = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_authState != null) return;
    final AppScope scope = AppScope.of(context);
    _authState = scope.auth.authStateChanges();
    _sideEffects = scope.auth.authStateChanges().listen((AppUser? user) {
      final String? uid = user?.uid;
      scope.analytics.setUserId(uid);
      scope.crashReporter.setUserIdentifier(uid);
      // Sign-in / sign-out from a pushed screen (Register, Forgot, …):
      // drop those routes so the gate's new root is visible.
      if (!_firstEvent && uid != _lastUid && mounted) {
        Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
      }
      _firstEvent = false;
      _lastUid = uid;
    });
  }

  @override
  void dispose() {
    _sideEffects?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _authState,
      builder: (BuildContext context, AsyncSnapshot<AppUser?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        final AppUser? user = snapshot.data;
        if (user == null) return const LoginScreen();
        // A new key per user resets tab state after switching accounts.
        return MainShell(key: ValueKey<String>(user.uid));
      },
    );
  }
}

/// Shown for the split second while Firebase restores the session.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(child: AppLogo.large()),
    );
  }
}
