import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';

/// Single-exercise lookup for the detail screen (and for resolving
/// exercise ids referenced by workouts / history).
class GetExerciseByIdUseCase {
  const GetExerciseByIdUseCase(this._repository);

  final ExerciseRepository _repository;

  Future<Exercise?> call(String id) => _repository.getExerciseById(id);
}
