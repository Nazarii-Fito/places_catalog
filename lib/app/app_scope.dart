import 'package:flutter/widgets.dart';

import '../data/repositories/auth_repository.dart';
import '../data/services/analytics_service.dart';
import '../data/services/crash_reporter.dart';

/// Gives every screen access to the app's services without a
/// state-management library: a plain [InheritedWidget] at the root.
///
/// `main.dart` passes the Firebase implementations; tests and the
/// screenshot mode pass fakes (e.g. `FakeAuthRepository`).
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.auth,
    required this.analytics,
    required this.crashReporter,
    required super.child,
  });

  final AuthRepository auth;
  final AnalyticsService analytics;
  final CrashReporter crashReporter;

  static AppScope of(BuildContext context) {
    final AppScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget.');
    return scope!;
  }

  /// The services never change at runtime, so dependents never rebuild.
  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
