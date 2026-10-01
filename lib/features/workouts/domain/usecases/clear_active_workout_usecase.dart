import 'package:forge_gym/features/workouts/domain/repositories/active_workout_repository.dart';

class ClearActiveWorkoutUseCase {
  const ClearActiveWorkoutUseCase(this._repository);

  final ActiveWorkoutRepository _repository;

  Future<void> call() => _repository.clear();
}
