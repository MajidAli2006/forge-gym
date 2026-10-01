import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_repository.dart';

class GetWorkoutsUseCase {
  const GetWorkoutsUseCase(this._repository);

  final WorkoutRepository _repository;

  Future<List<Workout>> call() => _repository.getWorkouts();
}
