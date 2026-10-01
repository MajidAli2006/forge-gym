/// Canonical analytics event names.
///
/// Features reference these constants so event naming stays consistent
/// across the app.
abstract final class AnalyticsEvents {
  static const String exerciseViewed = 'exercise_viewed';
  static const String exerciseFavourited = 'exercise_favourited';
  static const String workoutStarted = 'workout_started';
  static const String workoutCompleted = 'workout_completed';
  static const String setCompleted = 'set_completed';
  static const String customWorkoutCreated = 'custom_workout_created';
  static const String signUp = 'sign_up';
  static const String login = 'login';
}
