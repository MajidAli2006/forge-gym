import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/workouts/data/models/active_workout_dto.dart';
import 'package:forge_gym/features/workouts/data/models/completed_workout_dto.dart';
import 'package:forge_gym/features/workouts/data/models/workout_dto.dart';
import 'package:forge_gym/features/workouts/domain/entities/active_workout.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';

void main() {
  group('WorkoutDto', () {
    final json = <String, dynamic>{
      'id': 'push-day',
      'name': 'Push Day',
      'description': 'Chest, shoulders, triceps.',
      'difficulty': 'intermediate',
      'durationMinutes': 60,
      'targetMuscles': ['chest', 'shoulders', 'triceps'],
      'exercises': [
        {
          'exerciseId': 'bench-press-barbell',
          'sets': 4,
          'reps': 8,
          'restSeconds': 120,
          'order': 0,
        },
        {
          'exerciseId': 'push-up',
          'sets': 3,
          'reps': 12,
          'restSeconds': 60,
          'order': 1,
        },
      ],
    };

    test('fromJson -> toDomain maps fields and sorts by order', () {
      final workout = WorkoutDto.fromJson(json).toDomain();

      expect(workout.id, 'push-day');
      expect(workout.name, 'Push Day');
      expect(workout.difficulty, Difficulty.intermediate);
      expect(workout.targetMuscles, [
        MuscleGroup.chest,
        MuscleGroup.shoulders,
        MuscleGroup.triceps,
      ]);
      expect(workout.exercises.length, 2);
      expect(workout.exercises.first.exerciseId, 'bench-press-barbell');
      expect(workout.exercises.first.sets, 4);
      expect(workout.exercises.first.restSeconds, 120);
    });

    test('toDomain -> fromDomain -> toJson roundtrips', () {
      final domain = WorkoutDto.fromJson(json).toDomain();
      final roundtripped = WorkoutDto.fromDomain(domain).toJson();

      expect(roundtripped['id'], json['id']);
      expect(roundtripped['difficulty'], 'intermediate');
      expect(roundtripped['targetMuscles'], ['chest', 'shoulders', 'triceps']);
      final exercises = roundtripped['exercises'] as List;
      expect(exercises.length, 2);
      expect(
        (exercises.first as Map<String, dynamic>)['exerciseId'],
        'bench-press-barbell',
      );
    });

    test('full Workout entity roundtrip preserves equality', () {
      const original = Workout(
        id: 'w1',
        name: 'Test',
        description: 'desc',
        difficulty: Difficulty.beginner,
        durationMinutes: 30,
        targetMuscles: [MuscleGroup.legs],
        exercises: [
          WorkoutExercise(
            exerciseId: 'squat-barbell',
            sets: 3,
            reps: 10,
            restSeconds: 90,
            order: 0,
          ),
        ],
      );
      final restored = WorkoutDto.fromDomain(original).toDomain();
      expect(restored, original);
    });
  });

  group('ActiveWorkoutDto', () {
    ActiveWorkout buildSession() => ActiveWorkout(
      id: 'active-1',
      workoutId: 'push-day',
      workoutName: 'Push Day',
      startedAt: DateTime.utc(2026, 9, 29, 18, 0),
      currentExerciseIndex: 1,
      currentSetIndex: 1,
      status: ActiveWorkoutStatus.resting,
      exercises: const [
        ActiveExercise(
          exerciseId: 'bench-press-barbell',
          exerciseName: 'Barbell Bench Press',
          targetSets: 4,
          targetReps: 8,
          restSeconds: 120,
          sets: [
            ActiveSet(reps: 8, weightKg: 60, completed: true),
            ActiveSet(reps: 8, weightKg: 60, completed: true),
          ],
        ),
        ActiveExercise(
          exerciseId: 'push-up',
          exerciseName: 'Push Up',
          targetSets: 3,
          targetReps: 12,
          restSeconds: 60,
          sets: [
            ActiveSet(reps: 12, weightKg: 0, completed: true),
            ActiveSet(reps: 10, weightKg: 0),
            ActiveSet(reps: 12, weightKg: 0),
          ],
        ),
      ],
    );

    test('toJson -> fromJson roundtrips all fields', () {
      final session = buildSession();
      final restored = ActiveWorkoutDto.fromJson(
        ActiveWorkoutDto.fromDomain(session).toJson(),
      ).toDomain();

      expect(restored, session);
      expect(restored.currentExerciseIndex, 1);
      expect(restored.currentSetIndex, 1);
      expect(restored.status, ActiveWorkoutStatus.resting);
      expect(restored.currentExercise.exerciseId, 'push-up');
      expect(restored.currentExercise.sets.first.completed, isTrue);
    });
  });

  group('CompletedWorkoutDto', () {
    test('toJson -> fromJson roundtrips all fields', () {
      final completed = CompletedWorkout(
        id: 'cw-1',
        workoutId: 'push-day',
        workoutName: 'Push Day',
        startedAt: DateTime.utc(2026, 9, 29, 18, 0),
        finishedAt: DateTime.utc(2026, 9, 29, 19, 5),
        durationSeconds: 3900,
        totalVolumeKg: 2400,
        exercises: const [
          CompletedExercise(
            exerciseId: 'bench-press-barbell',
            exerciseName: 'Barbell Bench Press',
            sets: [
              PerformedSet(setNumber: 1, reps: 8, weightKg: 60),
              PerformedSet(setNumber: 2, reps: 8, weightKg: 60),
            ],
          ),
        ],
      );

      final restored = CompletedWorkoutDto.fromJson(
        CompletedWorkoutDto.fromDomain(completed).toJson(),
      ).toDomain();

      expect(restored, completed);
      expect(restored.totalSets, 2);
    });
  });

  group('ActiveWorkout entity logic', () {
    ActiveWorkout buildSession() => ActiveWorkout(
      id: 'active-1',
      workoutId: 'w1',
      workoutName: 'W1',
      startedAt: DateTime.utc(2026, 9, 29),
      exercises: const [
        ActiveExercise(
          exerciseId: 'e1',
          exerciseName: 'E1',
          targetSets: 2,
          targetReps: 10,
          restSeconds: 60,
          sets: [
            ActiveSet(reps: 10, weightKg: 0),
            ActiveSet(reps: 10, weightKg: 0),
          ],
        ),
        ActiveExercise(
          exerciseId: 'e2',
          exerciseName: 'E2',
          targetSets: 1,
          targetReps: 12,
          restSeconds: 60,
          sets: [ActiveSet(reps: 12, weightKg: 0)],
        ),
      ],
    );

    test('completeCurrentSet marks the set and enters resting', () {
      final updated = buildSession().completeCurrentSet(reps: 10, weightKg: 20);

      expect(updated.currentSet.completed, isTrue);
      expect(updated.currentSet.weightKg, 20);
      expect(updated.status, ActiveWorkoutStatus.resting);
    });

    test('advance moves through sets, exercises, then returns null', () {
      final s0 = buildSession();
      final s1 = s0.advance()!;
      expect(s1.currentSetIndex, 1);
      expect(s1.currentExerciseIndex, 0);

      final s2 = s1.advance()!;
      expect(s2.currentExerciseIndex, 1);
      expect(s2.currentSetIndex, 0);

      expect(s2.advance(), isNull);
    });

    test('moveToExercise clamps the index', () {
      final moved = buildSession().moveToExercise(99);
      expect(moved.currentExerciseIndex, 1);
      expect(moved.currentSetIndex, 0);
    });

    test('normalizedForResume clears resting status', () {
      final resting = buildSession().copyWith(
        status: ActiveWorkoutStatus.resting,
      );
      expect(
        resting.normalizedForResume().status,
        ActiveWorkoutStatus.inProgress,
      );
    });
  });
}
