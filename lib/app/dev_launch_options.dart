import '../data/mock/mock_places.dart';
import '../features/places/place_details_args.dart';
import 'routes/app_routes.dart';

/// Compile-time start options used to take screenshots of every screen
/// without tapping through the app or touching the network:
///
/// ```sh
/// flutter build ios --simulator --debug --dart-define=FAKE_AUTH=signed_in \
///   --dart-define=INITIAL_ROUTE=/home --dart-define=INITIAL_TAB=2
/// ```
///
/// Without the defines the app uses real Firebase Auth and starts at the
/// auth gate (Login or Home, depending on the saved session).
abstract final class DevLaunchOptions {
  static const String initialRoute = String.fromEnvironment(
    'INITIAL_ROUTE',
    defaultValue: AppRoutes.root,
  );

  /// `signed_in` / `signed_out` → use `FakeAuthRepository` instead of
  /// Firebase (screenshots); empty → real Firebase Auth.
  static const String fakeAuth = String.fromEnvironment('FAKE_AUTH');

  static bool get useFakeAuth => fakeAuth.isNotEmpty;

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
