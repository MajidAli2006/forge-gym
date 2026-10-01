import 'package:forge_gym/features/workouts/domain/repositories/active_workout_repository.dart';

class GetActiveWorkoutUseCase {
  const GetActiveWorkoutUseCase(this._repository);

  final ActiveWorkoutRepository _repository;

  Future<ActiveWorkout?> call() => _repository.load();
}
