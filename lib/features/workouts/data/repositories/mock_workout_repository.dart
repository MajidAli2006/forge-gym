import 'package:forge_gym/features/workouts/data/datasources/workout_local_datasource.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_repository.dart';

/// Workout plans from bundled mock JSON. Swapping in the API implementation
/// later only changes the DI registration — same domain interface.
class MockWorkoutRepository implements WorkoutRepository {
  MockWorkoutRepository(this._dataSource);

  final WorkoutLocalDataSource _dataSource;

  List<Workout>? _cache;

  @override
  Future<List<Workout>> getWorkouts() async {
    final cached = _cache;
    if (cached != null) return List<Workout>.unmodifiable(cached);
    final dtos = await _dataSource.loadWorkouts();
    final workouts = _byDifficulty(dtos.map((d) => d.toDomain()).toList());
    _cache = workouts;
    return List<Workout>.unmodifiable(workouts);
  }

  /// Beginner → intermediate → advanced, stable within each level.
  static List<Workout> _byDifficulty(List<Workout> workouts) {
    final indexed = workouts.asMap().entries.toList()
      ..sort((a, b) {
        final byLevel = a.value.difficulty.index.compareTo(
          b.value.difficulty.index,
        );
        return byLevel != 0 ? byLevel : a.key.compareTo(b.key);
      });
    return indexed.map((e) => e.value).toList();
  }

  @override
  Future<Workout?> getWorkoutById(String id) async {
    final workouts = await getWorkouts();
    for (final workout in workouts) {
      if (workout.id == id) return workout;
    }
    return null;
  }
}
