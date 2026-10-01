import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/workouts/data/datasources/workout_local_datasource.dart';
import 'package:forge_gym/features/workouts/data/models/workout_dto.dart';
import 'package:forge_gym/features/workouts/data/repositories/local_active_workout_repository.dart';
import 'package:forge_gym/features/workouts/data/repositories/local_workout_history_repository.dart';
import 'package:forge_gym/features/workouts/data/repositories/mock_workout_repository.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/active_workout_repository.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_workout_history_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_workouts_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/save_completed_workout_usecase.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workouts_cubit.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workouts_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test-only data source that reads the bundled JSON straight from disk.
///
/// [AssetWorkoutLocalDataSource] needs the asset registered in pubspec.yaml
/// (integration workstream owns that); this reads the same file directly so
/// the JSON content and DTO mapping stay covered either way.
class FileWorkoutLocalDataSource implements WorkoutLocalDataSource {
  @override
  Future<List<WorkoutDto>> loadWorkouts() async {
    final raw = await File('assets/mock/workouts.json').readAsString();
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => WorkoutDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Wraps a data source and counts [loadWorkouts] calls.
class _CountingDataSource implements WorkoutLocalDataSource {
  _CountingDataSource(this._inner);

  final WorkoutLocalDataSource _inner;
  int loadCount = 0;

  @override
  Future<List<WorkoutDto>> loadWorkouts() {
    loadCount++;
    return _inner.loadWorkouts();
  }
}

ActiveWorkout sampleActive() => ActiveWorkout(
  id: 'active-1',
  workoutId: 'push-day',
  workoutName: 'Push Day',
  startedAt: DateTime.utc(2026, 9, 29, 18),
  currentExerciseIndex: 0,
  currentSetIndex: 0,
  status: ActiveWorkoutStatus.inProgress,
  exercises: const [],
);

CompletedWorkout sampleCompleted(String id) => CompletedWorkout(
  id: id,
  workoutId: 'push-day',
  workoutName: 'Push Day',
  startedAt: DateTime.utc(2026, 9, 29, 18),
  finishedAt: DateTime.utc(2026, 9, 29, 19),
  durationSeconds: 3600,
  totalVolumeKg: 1500,
  exercises: const [],
);

void main() {
  group('MockWorkoutRepository', () {
    test('loads plans from the bundled asset', () async {
      final repository = MockWorkoutRepository(FileWorkoutLocalDataSource());

      final workouts = await repository.getWorkouts();

      expect(workouts.length, greaterThanOrEqualTo(8));
      expect(workouts.map((w) => w.id), contains('push-day'));
    });

    test('supports difficulty filtering', () async {
      final repository = MockWorkoutRepository(FileWorkoutLocalDataSource());

      final beginner = (await repository.getWorkouts())
          .where((w) => w.difficulty == Difficulty.beginner)
          .toList();

      expect(beginner, isNotEmpty);
      expect(
        beginner.every((w) => w.difficulty == Difficulty.beginner),
        isTrue,
      );
    });

    test('getWorkoutById returns null for unknown ids', () async {
      final repository = MockWorkoutRepository(FileWorkoutLocalDataSource());

      expect(await repository.getWorkoutById('nope'), isNull);
    });

    test('caches the bundle so the data source loads once', () async {
      final dataSource = _CountingDataSource(FileWorkoutLocalDataSource());
      final repository = MockWorkoutRepository(dataSource);

      final first = await repository.getWorkouts();
      final second = await repository.getWorkouts();

      expect(dataSource.loadCount, 1);
      expect(first.map((w) => w.id), second.map((w) => w.id));
    });
  });

  group('LocalActiveWorkoutRepository', () {
    late ActiveWorkoutRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repository = LocalActiveWorkoutRepository(
        await SharedPreferences.getInstance(),
      );
    });

    test('save/load roundtrips and clear removes the snapshot', () async {
      expect(await repository.load(), isNull);

      await repository.save(sampleActive());
      final loaded = await repository.load();
      expect(loaded, sampleActive());

      await repository.clear();
      expect(await repository.load(), isNull);
    });

    test('resting sessions normalize to inProgress after restore', () async {
      await repository.save(
        sampleActive().copyWith(status: ActiveWorkoutStatus.resting),
      );

      final loaded = await repository.load();
      expect(loaded!.status, ActiveWorkoutStatus.inProgress);
    });

    test('corrupt snapshots are dropped safely', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('forge.active_session', 'not-json{{');

      expect(await repository.load(), isNull);
      expect(prefs.containsKey('forge.active_session'), isFalse);
    });

    test('stale snapshots with out-of-range indices are dropped', () async {
      final stale = ActiveWorkout(
        id: 'stale-1',
        workoutId: 'push-day',
        workoutName: 'Push Day',
        startedAt: DateTime.utc(2026, 9, 29),
        currentExerciseIndex: 4,
        exercises: const [
          ActiveExercise(
            exerciseId: 'e1',
            exerciseName: 'E1',
            targetSets: 1,
            targetReps: 10,
            restSeconds: 60,
            sets: [ActiveSet(reps: 10, weightKg: 0)],
          ),
        ],
      );

      await repository.save(stale);

      expect(await repository.load(), isNull);
    });
  });

  group('LocalWorkoutHistoryRepository', () {
    late WorkoutHistoryRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repository = LocalWorkoutHistoryRepository(
        await SharedPreferences.getInstance(),
      );
    });

    test('append/prepend history newest-first and respect the limit', () async {
      final useCaseSave = SaveCompletedWorkoutUseCase(repository);
      await useCaseSave(sampleCompleted('cw-1'));
      await useCaseSave(sampleCompleted('cw-2'));

      final useCaseGet = GetWorkoutHistoryUseCase(repository);
      final history = await useCaseGet(limit: 50);

      expect(history.map((w) => w.id), ['cw-2', 'cw-1']);
      expect(history.first.totalVolumeKg, 1500);
    });
  });

  group('WorkoutsCubit', () {
    test('loads plans from the real asset bundle', () async {
      final cubit = WorkoutsCubit(
        GetWorkoutsUseCase(MockWorkoutRepository(FileWorkoutLocalDataSource())),
      );

      await cubit.load();

      expect(cubit.state.status, WorkoutsStatus.loaded);
      expect(cubit.state.workouts, isNotEmpty);
      await cubit.close();
    });

    blocTest<WorkoutsCubit, WorkoutsState>(
      'emits loading then loaded',
      build: () => WorkoutsCubit(
        GetWorkoutsUseCase(MockWorkoutRepository(FileWorkoutLocalDataSource())),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const WorkoutsState(status: WorkoutsStatus.loading),
        isA<WorkoutsState>().having(
          (s) => s.status,
          'status',
          WorkoutsStatus.loaded,
        ),
      ],
    );
  });
}
