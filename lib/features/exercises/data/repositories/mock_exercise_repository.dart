import 'package:forge_gym/features/exercises/data/datasources/exercise_local_datasource.dart';
import 'package:forge_gym/features/exercises/data/mappers/exercise_mapper.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';

/// Development implementation backed by the bundled mock JSON.
/// Filtering happens in memory; the API implementation will push these
/// filters to query parameters instead. UI is unaffected by the swap.
class MockExerciseRepository implements ExerciseRepository {
  MockExerciseRepository(
    this._dataSource, [
    this._mapper = const ExerciseMapper(),
  ]);

  final ExerciseLocalDataSource _dataSource;
  final ExerciseMapper _mapper;

  List<Exercise>? _cache;

  Future<List<Exercise>> _all() async {
    final cached = _cache;
    if (cached != null) return cached;
    final dtos = await _dataSource.loadExercises();
    final exercises = _byDifficulty(dtos.map(_mapper.toDomain).toList());
    _cache = exercises;
    return exercises;
  }

  /// Beginner → intermediate → advanced, keeping the bundle order within
  /// each level so members always meet the accessible movements first.
  static List<Exercise> _byDifficulty(List<Exercise> exercises) {
    final indexed = exercises.asMap().entries.toList()
      ..sort((a, b) {
        final byLevel = a.value.difficulty.index.compareTo(
          b.value.difficulty.index,
        );
        return byLevel != 0 ? byLevel : a.key.compareTo(b.key);
      });
    return indexed.map((e) => e.value).toList(growable: false);
  }

  @override
  Future<List<Exercise>> getExercises({
    String? query,
    MuscleGroup? muscle,
    Equipment? equipment,
    Difficulty? difficulty,
  }) async {
    final exercises = await _all();
    final needle = query?.trim().toLowerCase();

    return exercises
        .where((e) {
          if (muscle != null &&
              !e.primaryMuscles.contains(muscle) &&
              !e.secondaryMuscles.contains(muscle)) {
            return false;
          }
          if (equipment != null && e.equipment != equipment) return false;
          if (difficulty != null && e.difficulty != difficulty) return false;
          if (needle != null && needle.isNotEmpty) {
            final haystack = <String>[
              e.name,
              e.description,
              e.equipment.label,
              e.difficulty.label,
              ...e.primaryMuscles.map((m) => m.label),
              ...e.secondaryMuscles.map((m) => m.label),
            ].join(' ').toLowerCase();
            if (!haystack.contains(needle)) return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  @override
  Future<Exercise?> getExerciseById(String id) async {
    final exercises = await _all();
    for (final exercise in exercises) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }
}
