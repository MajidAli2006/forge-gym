import 'package:flutter/foundation.dart';

/// Abstraction over crash reporting.
///
/// Today this logs in debug builds. A `FirebaseCrashlyticsReporter` will
/// implement this interface later without touching any call site.
abstract class ErrorReporter {
  void recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  });
}

class DebugErrorReporter implements ErrorReporter {
  @override
  void recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    debugPrint(
      '[ErrorReporter] reason=$reason fatal=$fatal\n$error\n$stackTrace',
    );
  }
}
