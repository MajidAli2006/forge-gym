import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';

/// Finished-workout history. Read by the progress feature for stats,
/// streaks, and charts; written when a session finishes.
abstract class WorkoutHistoryRepository {
  Future<void> saveCompleted(CompletedWorkout workout);

  /// Finished workouts, newest first.
  Future<List<CompletedWorkout>> getHistory({int limit = 50});

  /// Replaces the entry with the same id, or saves it as new.
  Future<void> upsertCompleted(CompletedWorkout workout);

  /// Emits after every successful write so dashboards (home, progress)
  /// can refresh without the screen being rebuilt.
  Stream<void> get changes;
}
