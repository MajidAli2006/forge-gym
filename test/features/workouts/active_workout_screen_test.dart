import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
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
import 'package:forge_gym/features/workouts/presentation/screens/active_workout_screen.dart';
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

void main() {
  late MockGetWorkoutByIdUseCase getWorkoutById;
  late MockExerciseRepository exerciseRepository;

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
    final getActiveWorkout = MockGetActiveWorkoutUseCase();
    final saveActiveWorkout = MockSaveActiveWorkoutUseCase();
    final clearActiveWorkout = MockClearActiveWorkoutUseCase();
    final saveCompletedWorkout = MockSaveCompletedWorkoutUseCase();

    when(getActiveWorkout.call).thenAnswer((_) async => null);
    when(() => saveActiveWorkout(any())).thenAnswer((_) async {});
    when(clearActiveWorkout.call).thenAnswer((_) async {});
    when(() => saveCompletedWorkout(any())).thenAnswer((_) async {});
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
            restSeconds: 60,
            order: 0,
          ),
        ],
      ),
    );
    // No demo video bundled in tests -> placeholder tile.
    when(
      () => exerciseRepository.getExerciseById(any()),
    ).thenAnswer((_) async => null);

    getIt.registerFactory<WorkoutSessionCubit>(
      () => WorkoutSessionCubit(
        getWorkoutById: getWorkoutById,
        exerciseRepository: exerciseRepository,
        getActiveWorkout: getActiveWorkout,
        saveActiveWorkout: saveActiveWorkout,
        clearActiveWorkout: clearActiveWorkout,
        saveCompletedWorkout: saveCompletedWorkout,
      ),
    );
    getIt.registerSingleton<ExerciseRepository>(exerciseRepository);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ActiveWorkoutScreen(workoutId: 'quick')),
    );
    // Flush the chained async futures: initialize -> startWorkout.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('starts the workout and shows the first exercise', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Quick'), findsOneWidget);
    expect(find.text('Exercise 1 of 1'), findsOneWidget);
    expect(find.text('Set 1 of 1 • Target 10 reps'), findsOneWidget);
    expect(find.text('Complete set'), findsOneWidget);
  });

  testWidgets('completing a set shows the rest overlay', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Complete set'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Skip rest'), findsOneWidget);
    expect(find.text('+15 sec'), findsOneWidget);
    expect(find.text('Complete set'), findsNothing);
  });

  testWidgets('rest overlay skip finishes the last-set workout', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Complete set'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.ensureVisible(find.text('Skip rest'));
    await tester.tap(find.text('Skip rest'));
    // Let the async finish flow complete.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.text('Sets'), findsOneWidget);
    expect(find.text('kg lifted'), findsOneWidget);
  });

  testWidgets('rep stepper adjusts the value', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Increase Reps done'));
    await tester.pump();

    // Set editor shows the updated reps twice (semantics + value text).
    expect(find.text('11'), findsWidgets);
  });
}
