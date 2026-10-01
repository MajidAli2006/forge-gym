import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';

class GetWorkoutHistoryUseCase {
  const GetWorkoutHistoryUseCase(this._repository);

  final WorkoutHistoryRepository _repository;

  Future<List<CompletedWorkout>> call({int limit = 50}) =>
      _repository.getHistory(limit: limit);
}
