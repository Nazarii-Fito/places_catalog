import 'routes/app_routes.dart';

/// Compile-time start options used to take screenshots of every screen
/// without tapping through the app:
///
/// ```sh
/// flutter build ios --simulator --debug \
///   --dart-define=INITIAL_ROUTE=/home --dart-define=INITIAL_TAB=2
/// ```
///
/// Without the defines the app starts on Login with the Home tab.
abstract final class DevLaunchOptions {
  static const String initialRoute = String.fromEnvironment(
    'INITIAL_ROUTE',
    defaultValue: AppRoutes.login,
  );

  /// Index of the tab opened first in `MainShell` (0 — Home).
  static const int initialTab = int.fromEnvironment('INITIAL_TAB');
}
