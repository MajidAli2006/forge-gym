import 'package:forge_gym/features/workouts/domain/entities/workout.dart';

/// Routines the member builds themselves ("my diary"). Local today; the
/// same contract can be backed by an account-scoped API later.
abstract class CustomWorkoutRepository {
  /// Newest first.
  Future<List<Workout>> getAll();

  Future<Workout?> getById(String id);

  /// Inserts or replaces by id.
  Future<void> save(Workout workout);

  Future<void> delete(String id);

  /// Emits after every write.
  Stream<void> get changes;
}
