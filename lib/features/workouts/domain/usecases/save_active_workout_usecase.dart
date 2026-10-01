import 'package:forge_gym/features/workouts/domain/repositories/active_workout_repository.dart';

class SaveActiveWorkoutUseCase {
  const SaveActiveWorkoutUseCase(this._repository);

  final ActiveWorkoutRepository _repository;

  Future<void> call(ActiveWorkout session) => _repository.save(session);
}
