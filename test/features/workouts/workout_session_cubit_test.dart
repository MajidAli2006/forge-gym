import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:forge_gym/features/workouts/domain/entities/active_workout.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:forge_gym/features/workouts/domain/usecases/clear_active_workout_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_active_workout_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_workout_by_id_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/save_active_workout_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/save_completed_workout_usecase.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workout_session_cubit.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workout_session_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetWorkoutByIdUseCase extends Mock implements GetWorkoutByIdUseCase {}

class MockExerciseRepository extends Mock implements ExerciseRepository {}

class MockGetActiveWorkoutUseCase extends Mock
    implements GetActiveWorkoutUseCase {}

class MockSaveActiveWorkoutUseCase extends Mock
    implements SaveActiveWorkoutUseCase {}

class MockClearActiveWorkoutUseCase extends Mock
    implements ClearActiveWorkoutUseCase {}

class MockSaveCompletedWorkoutUseCase extends Mock
    implements SaveCompletedWorkoutUseCase {}

Workout sampleWorkout({int restSeconds = 90}) => Workout(
  id: 'push-day',
  name: 'Push Day',
  description: 'desc',
  difficulty: Difficulty.intermediate,
  durationMinutes: 60,
  targetMuscles: const [MuscleGroup.chest],
  exercises: [
    WorkoutExercise(
      exerciseId: 'push-up',
      sets: 2,
      reps: 10,
      restSeconds: restSeconds,
      order: 0,
    ),
    const WorkoutExercise(
      exerciseId: 'plank',
      sets: 1,
      reps: 1,
      restSeconds: 60,
      order: 1,
    ),
  ],
);

Exercise sampleExercise(String id, String name) => Exercise(
  id: id,
  name: name,
  description: 'desc',
  instructions: const ['Do it well.'],
  primaryMuscles: const [MuscleGroup.chest],
  secondaryMuscles: const [],
  equipment: Equipment.bodyweight,
  difficulty: Difficulty.beginner,
  thumbnailAsset: 'assets/exercises/$id/thumb.jpg',
  commonMistakes: const [],
  tips: const [],
  defaultSets: 3,
  defaultReps: 10,
  defaultRestSeconds: 60,
);

void main() {
  late MockGetWorkoutByIdUseCase getWorkoutById;
  late MockExerciseRepository exerciseRepository;
  late MockGetActiveWorkoutUseCase getActiveWorkout;
  late MockSaveActiveWorkoutUseCase saveActiveWorkout;
  late MockClearActiveWorkoutUseCase clearActiveWorkout;
  late MockSaveCompletedWorkoutUseCase saveCompletedWorkout;

  WorkoutSessionCubit buildCubit() => WorkoutSessionCubit(
    getWorkoutById: getWorkoutById,
    exerciseRepository: exerciseRepository,
    getActiveWorkout: getActiveWorkout,
    saveActiveWorkout: saveActiveWorkout,
    clearActiveWorkout: clearActiveWorkout,
    saveCompletedWorkout: saveCompletedWorkout,
  );

  setUpAll(() {
    registerFallbackValue(
      ActiveWorkout(
        id: 'x',
        workoutId: 'x',
        workoutName: 'x',
        startedAt: DateTime.utc(2026),
        exercises: const [],
      ),
    );
    registerFallbackValue(
      CompletedWorkout(
        id: 'x',
        workoutId: 'x',
        workoutName: 'x',
        startedAt: DateTime.utc(2026),
        finishedAt: DateTime.utc(2026),
        durationSeconds: 0,
        totalVolumeKg: 0,
        exercises: const [],
      ),
    );
  });

  setUp(() {
    getWorkoutById = MockGetWorkoutByIdUseCase();
    exerciseRepository = MockExerciseRepository();
    getActiveWorkout = MockGetActiveWorkoutUseCase();
    saveActiveWorkout = MockSaveActiveWorkoutUseCase();
    clearActiveWorkout = MockClearActiveWorkoutUseCase();
    saveCompletedWorkout = MockSaveCompletedWorkoutUseCase();

    when(() => getActiveWorkout()).thenAnswer((_) async => null);
    when(() => saveActiveWorkout(any())).thenAnswer((_) async {});
    when(() => clearActiveWorkout()).thenAnswer((_) async {});
    when(() => saveCompletedWorkout(any())).thenAnswer((_) async {});
    when(() => getWorkoutById(any())).thenAnswer((_) async => sampleWorkout());
    when(() => exerciseRepository.getExerciseById(any())).thenAnswer(
      (inv) async =>
          sampleExercise(inv.positionalArguments.first as String, 'Push Up'),
    );
  });

  group('initialize', () {
    blocTest<WorkoutSessionCubit, WorkoutSessionState>(
      'emits loading then initial when nothing is persisted',
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      expect: () => [
        const WorkoutSessionState(status: WorkoutSessionStatus.loading),
        const WorkoutSessionState(status: WorkoutSessionStatus.initial),
      ],
    );

    blocTest<WorkoutSessionCubit, WorkoutSessionState>(
      'emits loading then active when a session is persisted',
      build: buildCubit,
      setUp: () {
        when(() => getActiveWorkout()).thenAnswer(
          (_) async => ActiveWorkout(
            id: 'active-1',
            workoutId: 'push-day',
            workoutName: 'Push Day',
            startedAt: DateTime.utc(2026, 9, 29),
            exercises: const [],
          ),
        );
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [
        const WorkoutSessionState(status: WorkoutSessionStatus.loading),
        isA<WorkoutSessionState>()
            .having((s) => s.status, 'status', WorkoutSessionStatus.active)
            .having((s) => s.session?.id, 'session id', 'active-1'),
      ],
    );
  });

  group('startWorkout', () {
    blocTest<WorkoutSessionCubit, WorkoutSessionState>(
      'builds the session with resolved exercise names and persists it',
      build: buildCubit,
      act: (cubit) => cubit.startWorkout('push-day'),
      expect: () => [
        const WorkoutSessionState(status: WorkoutSessionStatus.loading),
        isA<WorkoutSessionState>().having(
          (s) => s.status,
          'status',
          WorkoutSessionStatus.active,
        ),
      ],
      verify: (_) {
        final saved = verify(() => saveActiveWorkout(captureAny())).captured;
        final session = saved.single as ActiveWorkout;
        expect(session.workoutId, 'push-day');
        expect(session.exercises.length, 2);
        expect(session.exercises.first.exerciseName, 'Push Up');
        expect(session.exercises.first.sets.length, 2);
      },
    );

    blocTest<WorkoutSessionCubit, WorkoutSessionState>(
      'emits an error when the workout is unknown',
      build: buildCubit,
      setUp: () {
        when(() => getWorkoutById(any())).thenAnswer((_) async => null);
      },
      act: (cubit) => cubit.startWorkout('nope'),
      expect: () => [
        const WorkoutSessionState(status: WorkoutSessionStatus.loading),
        const WorkoutSessionState(
          status: WorkoutSessionStatus.initial,
          errorMessage: 'Workout not found.',
        ),
      ],
    );
  });

  group('sets and rest timer', () {
    test(
      'completeSet marks the set, persists, and starts the rest timer',
      () async {
        final cubit = buildCubit();
        await cubit.startWorkout('push-day');

        await cubit.completeSet(reps: 10, weightKg: 20);

        final session = cubit.state.session!;
        expect(session.currentSet.completed, isTrue);
        expect(session.currentSet.weightKg, 20);
        expect(cubit.state.restSecondsLeft, 90);
        expect(cubit.state.isResting, isTrue);
        verify(() => saveActiveWorkout(any())).called(greaterThanOrEqualTo(2));
        await cubit.close();
      },
    );

    test('addRest15Seconds extends the countdown', () async {
      final cubit = buildCubit();
      await cubit.startWorkout('push-day');
      await cubit.completeSet(reps: 10, weightKg: 0);

      cubit.addRest15Seconds();

      expect(cubit.state.restSecondsLeft, 105);
      await cubit.close();
    });

    test('skipRest cancels the timer and advances to the next set', () async {
      final cubit = buildCubit();
      await cubit.startWorkout('push-day');
      await cubit.completeSet(reps: 10, weightKg: 0);

      await cubit.skipRest();

      expect(cubit.state.restSecondsLeft, 0);
      expect(cubit.state.session!.currentSetIndex, 1);
      await cubit.close();
    });

    test('rest timer auto-advances when the countdown reaches zero', () async {
      when(
        () => getWorkoutById(any()),
      ).thenAnswer((_) async => sampleWorkout(restSeconds: 1));
      final cubit = buildCubit();
      await cubit.startWorkout('push-day');
      await cubit.completeSet(reps: 10, weightKg: 0);
      expect(cubit.state.restSecondsLeft, 1);

      await Future<void>.delayed(const Duration(milliseconds: 1600));

      expect(cubit.state.restSecondsLeft, 0);
      expect(cubit.state.session!.currentSetIndex, 1);
      await cubit.close();
    });

    test('finishing the last set auto-finishes the workout', () async {
      when(() => getWorkoutById(any())).thenAnswer(
        (_) async => const Workout(
          id: 'quick',
          name: 'Quick',
          description: 'desc',
          difficulty: Difficulty.beginner,
          durationMinutes: 5,
          targetMuscles: [MuscleGroup.chest],
          exercises: [
            WorkoutExercise(
              exerciseId: 'push-up',
              sets: 1,
              reps: 10,
              restSeconds: 0,
              order: 0,
            ),
          ],
        ),
      );
      final cubit = buildCubit();
      await cubit.startWorkout('quick');

      // restSeconds: 0 -> advance() runs immediately after completeSet.
      await cubit.completeSet(reps: 10, weightKg: 20);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(cubit.state.status, WorkoutSessionStatus.finished);
      final saved = verify(() => saveCompletedWorkout(captureAny())).captured;
      final completed = saved.single as CompletedWorkout;
      expect(completed.totalVolumeKg, 200);
      expect(completed.totalSets, 1);
      verify(() => clearActiveWorkout()).called(1);
      await cubit.close();
    });
  });

  group('finishWorkout', () {
    test(
      'saves history with volume, clears the session, emits finished',
      () async {
        final cubit = buildCubit();
        await cubit.startWorkout('push-day');
        await cubit.completeSet(reps: 10, weightKg: 20);
        await cubit.skipRest();
        await cubit.completeSet(reps: 8, weightKg: 20);

        await cubit.finishWorkout();

        expect(cubit.state.status, WorkoutSessionStatus.finished);
        expect(cubit.state.session, isNull);
        final saved = verify(() => saveCompletedWorkout(captureAny())).captured;
        final completed = saved.single as CompletedWorkout;
        // 10x20 + 8x20
        expect(completed.totalVolumeKg, 360);
        expect(completed.exercises.length, 1);
        expect(completed.exercises.first.sets.length, 2);
        verify(() => clearActiveWorkout()).called(1);
        await cubit.close();
      },
    );

    test('discardWorkout clears without saving history', () async {
      final cubit = buildCubit();
      await cubit.startWorkout('push-day');

      await cubit.discardWorkout();

      expect(cubit.state.status, WorkoutSessionStatus.initial);
      verifyNever(() => saveCompletedWorkout(any()));
      verify(() => clearActiveWorkout()).called(1);
      await cubit.close();
    });
  });

  group('navigation between exercises', () {
    test('next/previous move the exercise index and reset the set', () async {
      final cubit = buildCubit();
      await cubit.startWorkout('push-day');

      await cubit.nextExercise();
      expect(cubit.state.session!.currentExerciseIndex, 1);
      expect(cubit.state.session!.currentSetIndex, 0);

      await cubit.previousExercise();
      expect(cubit.state.session!.currentExerciseIndex, 0);
      await cubit.close();
    });
  });
}
