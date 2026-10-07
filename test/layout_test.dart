import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/features/auth/screens/forgot_password_screen.dart';
import 'package:places_catalog/features/auth/screens/login_screen.dart';
import 'package:places_catalog/features/auth/screens/register_screen.dart';
import 'package:places_catalog/features/profile/screens/change_password_screen.dart';
import 'package:places_catalog/features/shell/main_shell.dart';

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

      testWidgets('Profile tab fits ${device.key} @ text x$scale', (
        WidgetTester tester,
      ) async {
        useIPhone(tester, size: device.value, textScale: scale);
        await tester.pumpWidget(testApp(const MainShell()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Profile').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Forgot Password success state fits iPhone SE', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: devices['iPhone SE']!, textScale: 1.2);
    await tester.pumpWidget(testApp(const ForgotPasswordScreen()));
    await tester.pumpAndSettle();
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
