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

  /// `--dart-define=PLACES_BACKEND=local` keeps the catalog in a JSON file
  /// on the device (the Lab 5 behaviour); the default is Cloud Firestore.
  /// Ignored in screenshot mode, which always uses memory.
  static const String placesBackend = String.fromEnvironment(
    'PLACES_BACKEND',
    defaultValue: 'firestore',
  );

  static bool get useLocalPlaces => placesBackend == 'local';

  /// Screenshot mode only: how long the in-memory catalog "loads", so the
  /// loading state can be captured (`FAKE_LOAD_DELAY_MS=60000`).
  static const int fakeLoadDelayMs = int.fromEnvironment(
    'FAKE_LOAD_DELAY_MS',
    defaultValue: 400,
  );

  /// Screenshot mode only: make loading fail to capture the error state.
  static const bool fakeLoadFail = bool.fromEnvironment('FAKE_LOAD_FAIL');

  /// `--dart-define=DEMO_FORM=true` pre-fills the "Add Place" form with the
  /// Figma demo content for screenshots; otherwise the form starts empty.
  static const bool demoForm = bool.fromEnvironment('DEMO_FORM');

  /// Used when Place Details is opened as the start screen (no caller to
  /// pass arguments): shows the first mock place.
  static PlaceDetailsArgs get previewDetailsArgs =>
      PlaceDetailsArgs(placeId: mockPlaces.first.id);
}
