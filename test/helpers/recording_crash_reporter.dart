import 'package:places_catalog/data/services/crash_reporter.dart';

/// Crash reporter that remembers non-fatal reports so tests can assert on
/// them.
class RecordingCrashReporter extends NoopCrashReporter {
  RecordingCrashReporter();

  final List<Object> errors = [];
  final List<String?> reasons = [];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    errors.add(error);
    reasons.add(reason);
  }
}
