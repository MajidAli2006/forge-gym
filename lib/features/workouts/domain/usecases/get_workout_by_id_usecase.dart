import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_repository.dart';

class GetWorkoutByIdUseCase {
  const GetWorkoutByIdUseCase(this._repository);

  final WorkoutRepository _repository;

  Future<Workout?> call(String id) => _repository.getWorkoutById(id);
}
