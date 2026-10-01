/// Central route definitions.
///
/// Widgets navigate via these constants — never with raw strings.
abstract final class AppRoutes {
  static const String home = '/home';
  static const String workouts = '/workouts';
  static const String exercises = '/exercises';
  static const String progress = '/progress';
  static const String profile = '/profile';

  /// Detail screen for a workout plan, e.g. `/workouts/push-day`.
  static String workoutDetail(String workoutId) => '$workouts/$workoutId';

  /// Editor for a brand-new personal routine.
  static const String newRoutine = '$workouts/new';

  /// Editor for an existing personal routine.
  static String editRoutine(String workoutId) => '$workouts/$workoutId/edit';

  /// Active training session for a workout plan.
  static String activeWorkout(String workoutId) =>
      '$workouts/$workoutId/active';

  /// Resumes the persisted in-progress session, or falls back to [workouts].
  static const String resumeWorkout = '$workouts/active/resume';

  /// Detail screen for an exercise, e.g. `/exercises/squat-barbell`.
  static String exerciseDetail(String exerciseId) => '$exercises/$exerciseId';

  /// Every exercise demo in one browsable grid.
  static const String videoLibrary = '$exercises/videos';

  /// Joinable challenges with live progress.
  static const String challenges = '$home/challenges';
}
