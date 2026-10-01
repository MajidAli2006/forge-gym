/// App-wide defaults.
///
/// Backend configuration lives in `EnvConfig`, not here.
abstract final class AppConstants {
  /// Default page size for paginated lists.
  static const int defaultPageSize = 20;

  /// Timeouts applied to the shared Dio client.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Finished workouts per week that count as "goal reached" on the
  /// progress dashboard. Becomes a per-member setting with the backend.
  static const int weeklyWorkoutGoal = 3;
}
