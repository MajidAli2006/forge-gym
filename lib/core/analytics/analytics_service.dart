import 'package:flutter/foundation.dart';

/// Analytics abstraction.
///
/// Presentation code depends on this — never on Firebase Analytics directly.
/// A `FirebaseAnalyticsService` will implement this interface once the
/// Firebase project is configured.
abstract class AnalyticsService {
  Future<void> logEvent(
    String name, [
    Map<String, Object?> parameters = const {},
  ]);
  Future<void> setUserId(String? userId);
  Future<void> setUserProperty(String name, String? value);
}

class DebugAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(
    String name, [
    Map<String, Object?> parameters = const {},
  ]) async {
    debugPrint('[Analytics] event=$name params=$parameters');
  }

  @override
  Future<void> setUserId(String? userId) async {
    debugPrint('[Analytics] setUserId=$userId');
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    debugPrint('[Analytics] setUserProperty $name=$value');
  }
}
