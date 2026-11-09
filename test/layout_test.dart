import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/features/auth/screens/forgot_password_screen.dart';
import 'package:places_catalog/features/auth/screens/login_screen.dart';
import 'package:places_catalog/features/auth/screens/register_screen.dart';
import 'package:places_catalog/data/mock/mock_places.dart';
import 'package:places_catalog/features/places/place_details_args.dart';
import 'package:places_catalog/features/places/screens/place_form_screen.dart';
import 'package:places_catalog/features/places/screens/location_picker_screen.dart';
import 'package:places_catalog/features/places/screens/place_details_screen.dart';
import 'package:places_catalog/features/profile/screens/change_password_screen.dart';
import 'package:places_catalog/features/profile/screens/edit_profile_screen.dart';
import 'package:places_catalog/features/profile/screens/export_archive_screen.dart';
import 'package:places_catalog/features/shell/main_shell.dart';

import 'package:places_catalog/data/repositories/in_memory_places_repository.dart';
import 'package:places_catalog/data/repositories/places_repository.dart';

import 'helpers/test_harness.dart';

/// Checks that no screen throws a RenderFlex overflow ("yellow-black
/// stripes") on the smallest and largest iPhones, with Dynamic Type 120 %
/// and with the keyboard open.
void main() {
  setUpAll(loadInterFont);

  const Map<String, Size> devices = {
    'iPhone SE': Size(375, 667),
    'iPhone 17 Pro Max': Size(440, 956),
  };

  final Map<String, Widget Function()> screens = {
    'Login': () => const LoginScreen(),
    'Register': () => const RegisterScreen(),
    'Forgot Password': () => const ForgotPasswordScreen(),
    'Change Password': () => const ChangePasswordScreen(),
    'Main shell (Home)': () => const MainShell(),
    'Place Details': () => PlaceDetailsScreen(
      args: PlaceDetailsArgs(placeId: mockPlaces.first.id),
    ),
    'Add Place': () => const PlaceFormScreen(),
    'Edit Place': () => PlaceFormScreen(initial: mockPlaces.first),
    'Location Picker': () => const LocationPickerScreen(),
    'Edit Profile': () => const EditProfileScreen(),
    'Export Archive': () => ExportArchiveScreen(places: mockPlaces),
  };

  for (final MapEntry<String, Size> device in devices.entries) {
    for (final double scale in [1.0, 1.2]) {
      for (final MapEntry<String, Widget Function()> screen
          in screens.entries) {
        testWidgets('${screen.key} fits ${device.key} @ text x$scale', (
          WidgetTester tester,
        ) async {
          useIPhone(tester, size: device.value, textScale: scale);
          await tester.pumpWidget(testApp(screen.value()));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }

      for (final String tab in ['Favorites', 'Profile']) {
        testWidgets('$tab tab fits ${device.key} @ text x$scale', (
          WidgetTester tester,
        ) async {
          useIPhone(tester, size: device.value, textScale: scale);
          await tester.pumpWidget(testApp(const MainShell()));
          await tester.pumpAndSettle();
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  homeStateLayoutTests();

  testWidgets('Forgot Password success state fits iPhone SE', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: devices['iPhone SE']!, textScale: 1.2);
    await tester.pumpWidget(testApp(const ForgotPasswordScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'me@icloud.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();
    expect(find.text('Check your email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final MapEntry<String, Widget Function()> screen in screens.entries) {
    testWidgets('${screen.key} has no overflow with the keyboard open', (
      WidgetTester tester,
    ) async {
      useIPhone(tester, size: devices['iPhone SE']!, keyboard: 291);
      await tester.pumpWidget(testApp(screen.value()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

/// Home's loading, error and empty states must also fit every screen size
/// and Dynamic Type setting (Lab 5).
void homeStateLayoutTests() {
  const Map<String, Size> devices = {
    'iPhone SE': Size(375, 667),
    'iPhone 17 Pro Max': Size(440, 956),
  };
  for (final MapEntry<String, Size> device in devices.entries) {
    for (final double scale in [1.0, 1.2]) {
      final Map<String, PlacesRepository> repos = {
        'loading': InMemoryPlacesRepository(delay: const Duration(days: 1)),
        'error': InMemoryPlacesRepository(failLoad: true),
        'empty catalog': InMemoryPlacesRepository(seed: const []),
      };
      for (final MapEntry<String, PlacesRepository> state in repos.entries) {
        testWidgets('Home ${state.key} fits ${device.key} @ text x$scale', (
          WidgetTester tester,
        ) async {
          useIPhone(tester, size: device.value, textScale: scale);
          await tester.pumpWidget(
            testApp(const MainShell(), places: state.value),
          );
          // A pending 1-day timer (loading) must not be "settled" away.
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
          // Let the simulated slow load finish: no timer may outlive the test.
          await tester.pump(const Duration(days: 1));
        });
      }
    }
  }
}
