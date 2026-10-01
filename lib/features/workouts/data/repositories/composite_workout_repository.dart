import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/custom_workout_repository.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_repository.dart';

/// Presents the gym's plans and the member's own routines as one catalogue,
/// so sessions, history, home and challenges need no idea which is which.
/// Routines come first (they are the member's), then the bundled plans.
class CompositeWorkoutRepository implements WorkoutRepository {
  const CompositeWorkoutRepository({
    required WorkoutRepository plans,
    required CustomWorkoutRepository custom,
  }) : _plans = plans,
       _custom = custom;

  final WorkoutRepository _plans;
  final CustomWorkoutRepository _custom;

  @override
  Future<List<Workout>> getWorkouts() async {
    final custom = await _custom.getAll();
    final plans = await _plans.getWorkouts();
    return List<Workout>.unmodifiable(<Workout>[...custom, ...plans]);
  }

  @override
  Future<Workout?> getWorkoutById(String id) async =>
      await _custom.getById(id) ?? await _plans.getWorkoutById(id);
}
