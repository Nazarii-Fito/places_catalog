import 'package:flutter/cupertino.dart';

import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
import '../../features/shell/main_shell.dart';

/// Route names and the single route factory of the app.
///
/// Every screen is wrapped in a [CupertinoPageRoute]: iOS slide transition
/// plus swipe-back from the left edge (HIG — no system "Back" button).
abstract final class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String changePassword = '/change-password';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final WidgetBuilder builder = switch (settings.name) {
      AppRoutes.register => (_) => const RegisterScreen(),
      AppRoutes.forgotPassword => (_) => const ForgotPasswordScreen(),
      AppRoutes.home => (_) => const MainShell(),
      AppRoutes.changePassword => (_) => const ChangePasswordScreen(),
      _ => (_) => const LoginScreen(),
    };
    return CupertinoPageRoute<void>(builder: builder, settings: settings);
  }
}
