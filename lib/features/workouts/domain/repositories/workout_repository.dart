import 'package:forge_gym/features/workouts/domain/entities/workout.dart';

/// Contract for workout plans. The mock (local JSON) and future API
/// implementations both satisfy this — presentation never knows which.
abstract class WorkoutRepository {
  Future<List<Workout>> getWorkouts();
  Future<Workout?> getWorkoutById(String id);
}
