import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/app/app_scope.dart';
import 'package:places_catalog/app/routes/app_routes.dart';
import 'package:places_catalog/core/theme/app_theme.dart';
import 'package:places_catalog/data/repositories/auth_repository.dart';
import 'package:places_catalog/data/repositories/fake_auth_repository.dart';
import 'package:places_catalog/data/services/analytics_service.dart';
import 'package:places_catalog/data/services/crash_reporter.dart';

/// Loads the real Inter font so text is measured like on a device
/// (the default test font "Ahem" draws every glyph as a square).
Future<void> loadInterFont() async {
  final FontLoader loader = FontLoader('Inter');
  for (final String weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
  }
  await loader.load();
}

/// Simulates an iPhone screen: logical [size], safe-area insets,
/// optional keyboard height and Dynamic Type scale.
void useIPhone(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  double keyboard = 0,
  double topInset = 47,
  double bottomInset = 34,
}) {
  const double dpr = 3;
  tester.view
    ..devicePixelRatio = dpr
    ..physicalSize = size * dpr
    ..padding = FakeViewPadding(top: topInset * dpr, bottom: bottomInset * dpr)
    ..viewInsets = FakeViewPadding(bottom: keyboard * dpr);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Services for tests: [auth] defaults to a signed-in fake user, Analytics
/// and Crashlytics do nothing.
Widget withScope(Widget child, {AuthRepository? auth}) {
  return AppScope(
    auth: auth ?? FakeAuthRepository.signedIn(),
    analytics: const NoopAnalyticsService(),
    crashReporter: const NoopCrashReporter(),
    child: child,
  );
}

/// The app's theme and router around [home], inside an [AppScope].
Widget testApp(Widget home, {AuthRepository? auth}) {
  return withScope(
    MaterialApp(
      theme: AppTheme.light,
      home: home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    ),
    auth: auth,
  );
}

/// iPhone 17: 402 × 874 pt, Dynamic Island safe area 62 pt / home bar 34 pt.
void useIPhone17(WidgetTester tester) =>
    useIPhone(tester, size: const Size(402, 874), topInset: 62);

/// How far the first scrollable on screen can scroll (0 = fits the screen).
double maxScrollExtent(WidgetTester tester) => tester
    .state<ScrollableState>(find.byType(Scrollable).first)
    .position
    .maxScrollExtent;
