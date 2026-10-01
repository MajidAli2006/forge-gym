import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';

class SaveCompletedWorkoutUseCase {
  const SaveCompletedWorkoutUseCase(this._repository);

  final WorkoutHistoryRepository _repository;

  Future<void> call(CompletedWorkout workout) =>
      _repository.saveCompleted(workout);
}
