import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

/// Contract for exercise data. The mock (local JSON) and future API
/// implementations both satisfy this — presentation never knows which.
abstract class ExerciseRepository {
  /// All exercises matching the optional filters. Null filter = no filter.
  Future<List<Exercise>> getExercises({
    String? query,
    MuscleGroup? muscle,
    Equipment? equipment,
    Difficulty? difficulty,
  });

  /// Single exercise by id, or null when unknown.
  Future<Exercise?> getExerciseById(String id);
}
