import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/app_logo.dart';
import '../data/repositories/user_profile_repository.dart';
import '../data/services/analytics_service.dart';
import '../data/services/crash_reporter.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/session/bloc/auth_bloc.dart';
import '../features/shell/main_shell.dart';

/// Root of the app: shows Login or [MainShell] depending on [AuthBloc].
///
/// * UI = f(state): a `BlocBuilder` maps `AuthState` to a screen. Firebase
///   keeps the session on the device, so after a restart a signed-in user
///   goes straight to [MainShell] — session restore.
/// * Side effects (clearing pushed auth screens, analytics / crash user id)
///   live in a `BlocListener`, never inside `build()`.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Who is signed in is tagged on Analytics and Crashlytics reports.
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (AuthState before, AuthState now) =>
              _uid(before) != _uid(now),
          listener: (BuildContext context, AuthState state) {
            final String? uid = _uid(state);
            context.read<AnalyticsService>().setUserId(uid);
            context.read<CrashReporter>().setUserIdentifier(uid);
            // First sign-in on this device creates/refreshes `users/{uid}`.
            if (state is Authenticated) {
              context.read<UserProfileRepository>().syncProfile(state.user);
            }
          },
        ),
        // Signed in / out from a pushed screen (Register, Forgot, …): drop
        // those routes so the gate's new root is visible. Not for the very
        // first state (session restore) — nothing is pushed yet.
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (AuthState before, AuthState now) =>
              before is! AuthInitial && _uid(before) != _uid(now),
          listener: (BuildContext context, AuthState state) {
            Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (BuildContext context, AuthState state) => switch (state) {
          AuthInitial() => const _Splash(),
          Unauthenticated() => const LoginScreen(),
          // A new key per user resets tab state after switching accounts.
          Authenticated(:final user) => MainShell(
            key: ValueKey<String>(user.uid),
          ),
        },
      ),
    );
  }

  static String? _uid(AuthState state) =>
      state is Authenticated ? state.user.uid : null;
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
