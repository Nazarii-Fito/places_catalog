import '../data/mock/mock_places.dart';
import '../features/places/place_details_args.dart';
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

  /// Used when Place Details is opened as the start screen (no caller to
  /// pass arguments): shows the first mock place with inert callbacks.
  static PlaceDetailsArgs get previewDetailsArgs => PlaceDetailsArgs(
    place: mockPlaces.first,
    onToggleFavorite: (_) {},
    onUpdate: (_) {},
    onDelete: (_) {},
  );
}
