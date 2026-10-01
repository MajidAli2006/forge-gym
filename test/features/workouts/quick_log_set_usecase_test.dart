import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/core/errors/failures.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';
import 'package:forge_gym/features/workouts/domain/usecases/quick_log_set_usecase.dart';

class _History implements WorkoutHistoryRepository {
  final List<CompletedWorkout> items = <CompletedWorkout>[];

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<List<CompletedWorkout>> getHistory({int limit = 50}) async => items;

  @override
  Future<void> saveCompleted(CompletedWorkout workout) async =>
      items.insert(0, workout);

  @override
  Future<void> upsertCompleted(CompletedWorkout workout) async {
    final index = items.indexWhere((w) => w.id == workout.id);
    if (index == -1) {
      items.insert(0, workout);
    } else {
      items[index] = workout;
    }
  }
}

const _curl = Exercise(
  id: 'bicep-curl-dumbbell',
  name: 'Dumbbell Bicep Curl',
  description: '',
  instructions: <String>[],
  primaryMuscles: <MuscleGroup>[MuscleGroup.biceps],
  secondaryMuscles: <MuscleGroup>[],
  equipment: Equipment.dumbbell,
  difficulty: Difficulty.beginner,
  thumbnailAsset: 't.jpg',
  commonMistakes: <String>[],
  tips: <String>[],
  defaultSets: 3,
  defaultReps: 12,
  defaultRestSeconds: 60,
);

const _plank = Exercise(
  id: 'plank',
  name: 'Plank',
  description: '',
  instructions: <String>[],
  primaryMuscles: <MuscleGroup>[MuscleGroup.core],
  secondaryMuscles: <MuscleGroup>[],
  equipment: Equipment.bodyweight,
  difficulty: Difficulty.beginner,
  thumbnailAsset: 't.jpg',
  commonMistakes: <String>[],
  tips: <String>[],
  defaultSets: 3,
  defaultReps: 30,
  defaultRestSeconds: 60,
  tracking: TrackingType.timed,
);

void main() {
  final morning = DateTime(2026, 9, 30, 9);
  final evening = DateTime(2026, 9, 30, 19);

  test('sets logged on the same day merge into one Quick log entry', () async {
    final history = _History();
    final useCase = QuickLogSetUseCase(history);

    await useCase(exercise: _curl, count: 12, weightKg: 10, now: morning);
    await useCase(exercise: _curl, count: 10, weightKg: 12.5, now: evening);
    await useCase(exercise: _plank, count: 45, now: evening);

    expect(history.items, hasLength(1));
    final entry = history.items.single;
    expect(entry.workoutName, 'Quick log');
    expect(entry.exercises, hasLength(2));
    expect(entry.exercises.first.sets.map((s) => s.reps), <int>[12, 10]);
    expect(entry.exercises.first.sets.last.setNumber, 2);
    expect(entry.totalVolumeKg, 12 * 10 + 10 * 12.5);
    expect(entry.exercises.last.tracking, TrackingType.timed);
    expect(entry.exercises.last.sets.single.reps, 45);
    expect(entry.startedAt, morning);
    expect(entry.finishedAt, evening);
  });

  test('a new day starts a new entry', () async {
    final history = _History();
    final useCase = QuickLogSetUseCase(history);
    await useCase(exercise: _curl, count: 12, weightKg: 10, now: morning);
    await useCase(
      exercise: _curl,
      count: 12,
      weightKg: 10,
      now: morning.add(const Duration(days: 1)),
    );
    expect(history.items, hasLength(2));
  });

  test('rejects an empty set', () async {
    final useCase = QuickLogSetUseCase(_History());
    await expectLater(
      useCase(exercise: _curl, count: 0, now: morning),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
