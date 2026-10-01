import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';

/// Filters forwarded straight to the repository; the use case exists so
/// presentation depends on domain intent, not on the repository directly.
class GetExercisesUseCase {
  const GetExercisesUseCase(this._repository);

  final ExerciseRepository _repository;

  Future<List<Exercise>> call({
    String? query,
    MuscleGroup? muscle,
    Equipment? equipment,
    Difficulty? difficulty,
  }) {
    return _repository.getExercises(
      query: query,
      muscle: muscle,
      equipment: equipment,
      difficulty: difficulty,
    );
  }
}
