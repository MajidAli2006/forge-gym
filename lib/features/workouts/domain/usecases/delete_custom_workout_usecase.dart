import 'package:forge_gym/features/workouts/domain/repositories/custom_workout_repository.dart';

class DeleteCustomWorkoutUseCase {
  const DeleteCustomWorkoutUseCase(this._custom);

  final CustomWorkoutRepository _custom;

  Future<void> call(String id) => _custom.delete(id);
}
