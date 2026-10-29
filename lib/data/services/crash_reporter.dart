import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Crash & error reporting API used by the app (wraps Crashlytics).
abstract interface class CrashReporter {
  /// Ties reports to a user. Uses the Firebase uid — never e-mail or name.
  Future<void> setUserIdentifier(String? uid);

  /// Breadcrumb shown in the "Logs" tab of the next report.
  Future<void> log(String message);

  /// Non-fatal by default: the app keeps running, the issue is still
  /// reported. `fatal: true` only marks the report — it does not exit.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  });

  /// Developer menu: a handled test error that appears in Crashlytics.
  Future<void> sendTestNonFatal();

  /// Developer menu: terminates the app with a native test crash.
  void forceTestCrash();
}

class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> setUserIdentifier(String? uid) =>
      _crashlytics.setUserIdentifier(uid ?? '');

  @override
  Future<void> log(String message) => _crashlytics.log(message);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) => _crashlytics.recordError(error, stack, reason: reason, fatal: fatal);

  @override
  Future<void> sendTestNonFatal() async {
    await log('Developer menu: test non-fatal error');
    await recordError(
      StateError('PlacesCatalog test non-fatal error'),
      StackTrace.current,
      reason: 'Triggered from the Profile developer menu',
    );
  }

  @override
  void forceTestCrash() => _crashlytics.crash();
}

/// Does nothing — used by widget tests and the screenshot mode.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> setUserIdentifier(String? uid) async {}
  @override
  Future<void> log(String message) async {}
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {}
  @override
  Future<void> sendTestNonFatal() async {}
  @override
  void forceTestCrash() {}
}
