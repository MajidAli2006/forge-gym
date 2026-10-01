import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/core/errors/failures.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:forge_gym/features/workouts/data/repositories/composite_workout_repository.dart';
import 'package:forge_gym/features/workouts/data/repositories/prefs_custom_workout_repository.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_repository.dart';
import 'package:forge_gym/features/workouts/domain/usecases/save_custom_workout_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pushUp = Exercise(
  id: 'push-up',
  name: 'Push Up',
  description: '',
  instructions: <String>[],
  primaryMuscles: <MuscleGroup>[MuscleGroup.chest],
  secondaryMuscles: <MuscleGroup>[MuscleGroup.triceps],
  equipment: Equipment.bodyweight,
  difficulty: Difficulty.beginner,
  thumbnailAsset: 't.jpg',
  commonMistakes: <String>[],
  tips: <String>[],
  defaultSets: 3,
  defaultReps: 15,
  defaultRestSeconds: 60,
  tracking: TrackingType.bodyweightReps,
);

const _squat = Exercise(
  id: 'squat-barbell',
  name: 'Barbell Squat',
  description: '',
  instructions: <String>[],
  primaryMuscles: <MuscleGroup>[MuscleGroup.legs, MuscleGroup.glutes],
  secondaryMuscles: <MuscleGroup>[],
  equipment: Equipment.barbell,
  difficulty: Difficulty.advanced,
  thumbnailAsset: 't.jpg',
  commonMistakes: <String>[],
  tips: <String>[],
  defaultSets: 4,
  defaultReps: 8,
  defaultRestSeconds: 150,
);

class _Exercises implements ExerciseRepository {
  @override
  Future<Exercise?> getExerciseById(String id) async =>
      <Exercise>[_pushUp, _squat].where((e) => e.id == id).firstOrNull;

  @override
  Future<List<Exercise>> getExercises({
    String? query,
    MuscleGroup? muscle,
    Equipment? equipment,
    Difficulty? difficulty,
  }) async => <Exercise>[_pushUp, _squat];
}

class _Plans implements WorkoutRepository {
  static const plan = Workout(
    id: 'push-day',
    name: 'Push Day',
    description: '',
    difficulty: Difficulty.intermediate,
    durationMinutes: 60,
    targetMuscles: <MuscleGroup>[MuscleGroup.chest],
    exercises: <WorkoutExercise>[],
  );

  @override
  Future<List<Workout>> getWorkouts() async => const <Workout>[plan];

  @override
  Future<Workout?> getWorkoutById(String id) async =>
      id == plan.id ? plan : null;
}

void main() {
  late PrefsCustomWorkoutRepository custom;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    custom = PrefsCustomWorkoutRepository(
      await SharedPreferences.getInstance(),
    );
  });

  group('SaveCustomWorkoutUseCase', () {
    test('derives level, muscles and duration and persists the routine', () async {
      final useCase = SaveCustomWorkoutUseCase(custom, _Exercises());
      final saved = await useCase(
        name: '  Monday push  ',
        description: 'Keep it strict',
        exercises: const <WorkoutExercise>[
          WorkoutExercise(
            exerciseId: 'squat-barbell',
            sets: 4,
            reps: 8,
            restSeconds: 120,
            order: 5,
          ),
          WorkoutExercise(
            exerciseId: 'push-up',
            sets: 3,
            reps: 15,
            restSeconds: 60,
            order: 2,
          ),
        ],
        now: DateTime(2026, 9, 30, 10),
      );

      expect(saved.name, 'Monday push');
      expect(saved.isCustom, isTrue);
      expect(saved.difficulty, Difficulty.advanced);
      expect(saved.targetMuscles, <MuscleGroup>[
        MuscleGroup.legs,
        MuscleGroup.glutes,
        MuscleGroup.chest,
      ]);
      // 4×(40+120) + 3×(40+60) = 940 s → 16 min → rounded up to 20.
      expect(saved.durationMinutes, 20);
      expect(saved.exercises.map((e) => e.order), <int>[0, 1]);

      final stored = await custom.getAll();
      expect(stored.single.id, saved.id);
      expect(stored.single.isCustom, isTrue);
    });

    test('rejects a routine without a name or exercises', () async {
      final useCase = SaveCustomWorkoutUseCase(custom, _Exercises());
      await expectLater(
        useCase(name: '   ', exercises: const <WorkoutExercise>[]),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        useCase(name: 'Legs', exercises: const <WorkoutExercise>[]),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('saving with the same id replaces the routine', () async {
      final useCase = SaveCustomWorkoutUseCase(custom, _Exercises());
      const item = WorkoutExercise(
        exerciseId: 'push-up',
        sets: 3,
        reps: 10,
        restSeconds: 60,
        order: 0,
      );
      final first = await useCase(name: 'A', exercises: const [item]);
      await useCase(id: first.id, name: 'B', exercises: const [item]);
      final all = await custom.getAll();
      expect(all, hasLength(1));
      expect(all.single.name, 'B');
    });
  });

  group('CompositeWorkoutRepository', () {
    test('lists routines before plans and resolves ids from both', () async {
      await custom.save(
        const Workout(
          id: 'custom-1',
          name: 'Mine',
          description: '',
          difficulty: Difficulty.beginner,
          durationMinutes: 20,
          targetMuscles: <MuscleGroup>[],
          exercises: <WorkoutExercise>[],
          isCustom: true,
        ),
      );
      final repo = CompositeWorkoutRepository(plans: _Plans(), custom: custom);
      final all = await repo.getWorkouts();
      expect(all.map((w) => w.id), <String>['custom-1', 'push-day']);
      expect((await repo.getWorkoutById('custom-1'))?.isCustom, isTrue);
      expect((await repo.getWorkoutById('push-day'))?.name, 'Push Day');
      expect(await repo.getWorkoutById('nope'), isNull);
    });

    test('delete removes the routine and notifies listeners', () async {
      var notified = 0;
      final sub = custom.changes.listen((_) => notified++);
      await custom.save(
        const Workout(
          id: 'custom-1',
          name: 'Mine',
          description: '',
          difficulty: Difficulty.beginner,
          durationMinutes: 20,
          targetMuscles: <MuscleGroup>[],
          exercises: <WorkoutExercise>[],
          isCustom: true,
        ),
      );
      await custom.delete('custom-1');
      await Future<void>.delayed(Duration.zero);
      expect(await custom.getAll(), isEmpty);
      expect(notified, 2);
      await sub.cancel();
    });
  });
}
