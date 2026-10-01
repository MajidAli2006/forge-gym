import 'package:forge_gym/features/workouts/domain/entities/active_workout.dart';

export 'package:forge_gym/features/workouts/domain/entities/active_workout.dart';

/// Persists the in-progress session so it survives backgrounding, phone
/// lock, and process termination. Results sync later when connectivity
/// returns (future backend work); for now the device is the source of truth.
abstract class ActiveWorkoutRepository {
  /// Saves (overwrites) the current session.
  Future<void> save(ActiveWorkout session);

  /// The in-progress session, normalized for resume, or null when none.
  Future<ActiveWorkout?> load();

  /// Drops the in-progress session (finished or discarded).
  Future<void> clear();
}
