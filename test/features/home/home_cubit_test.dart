import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';
import 'package:forge_gym/features/auth/domain/repositories/auth_repository.dart';
import 'package:forge_gym/features/challenges/domain/entities/challenge.dart';
import 'package:forge_gym/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:forge_gym/features/challenges/domain/usecases/get_challenge_progress_usecase.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:forge_gym/features/home/domain/entities/announcement.dart';
import 'package:forge_gym/features/home/domain/repositories/announcement_repository.dart';
import 'package:forge_gym/features/home/domain/usecases/get_announcements_usecase.dart';
import 'package:forge_gym/features/home/presentation/cubit/home_cubit.dart';
import 'package:forge_gym/features/home/presentation/cubit/home_state.dart';
import 'package:forge_gym/features/progress/domain/usecases/get_progress_summary_usecase.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/active_workout_repository.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_repository.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_workouts_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

class MockActiveWorkoutRepository extends Mock
    implements ActiveWorkoutRepository {}

class MockWorkoutHistoryRepository extends Mock
    implements WorkoutHistoryRepository {}

class MockExerciseRepository extends Mock implements ExerciseRepository {}

class MockAnnouncementRepository extends Mock
    implements AnnouncementRepository {}

class MockGetChallengeProgressUseCase extends Mock
    implements GetChallengeProgressUseCase {}

class MockChallengeEnrollmentRepository extends Mock
    implements ChallengeEnrollmentRepository {}

const _user = User(
  id: 'u1',
  name: 'Majid',
  email: 'majid@example.com',
  fitnessLevel: FitnessLevel.beginner,
);

const _workout1 = Workout(
  id: 'w1',
  name: 'Push Day',
  description: 'Chest, shoulders, triceps',
  difficulty: Difficulty.intermediate,
  durationMinutes: 45,
  targetMuscles: [MuscleGroup.chest],
  exercises: [],
);

const _workout2 = Workout(
  id: 'w2',
  name: 'Pull Day',
  description: 'Back and biceps',
  difficulty: Difficulty.beginner,
  durationMinutes: 40,
  targetMuscles: [MuscleGroup.back],
  exercises: [],
);

const _exercise = Exercise(
  id: 'e1',
  name: 'Push Up',
  description: 'Bodyweight chest exercise',
  instructions: ['Lower your chest to the floor'],
  primaryMuscles: [MuscleGroup.chest],
  secondaryMuscles: [MuscleGroup.triceps],
  equipment: Equipment.bodyweight,
  difficulty: Difficulty.beginner,
  thumbnailAsset: 'assets/exercises/push-up/thumb.jpg',
  commonMistakes: ['Sagging hips'],
  tips: ['Keep your core tight'],
  defaultSets: 3,
  defaultReps: 10,
  defaultRestSeconds: 60,
);

CompletedWorkout _finishedWorkout() => CompletedWorkout(
  id: 'cw1',
  workoutId: 'w1',
  workoutName: 'Push Day',
  startedAt: DateTime(2026, 9, 30, 8),
  finishedAt: DateTime(2026, 9, 30, 9),
  durationSeconds: 3600,
  totalVolumeKg: 1200,
  exercises: const [
    CompletedExercise(
      exerciseId: 'e1',
      exerciseName: 'Push Up',
      sets: [PerformedSet(setNumber: 1, reps: 10, weightKg: 0)],
    ),
  ],
);

HomeCubit buildCubit({
  required MockAuthRepository auth,
  required MockWorkoutRepository workouts,
  required MockActiveWorkoutRepository active,
  required MockWorkoutHistoryRepository history,
  required MockExerciseRepository exercises,
  required MockAnnouncementRepository announcements,
}) {
  final challengeProgress = MockGetChallengeProgressUseCase();
  when(
    challengeProgress.call,
  ).thenAnswer((_) async => const <ChallengeProgress>[]);
  final enrollments = MockChallengeEnrollmentRepository();
  when(() => enrollments.changes).thenAnswer((_) => const Stream<void>.empty());
  return HomeCubit(
    authRepository: auth,
    getWorkoutsUseCase: GetWorkoutsUseCase(workouts),
    activeWorkoutRepository: active,
    workoutHistoryRepository: history,
    exerciseRepository: exercises,
    getProgressSummaryUseCase: GetProgressSummaryUseCase(history),
    getAnnouncementsUseCase: GetAnnouncementsUseCase(announcements),
    getChallengeProgress: challengeProgress,
    challengeEnrollments: enrollments,
  );
}

void stubHappyPath({
  required MockAuthRepository auth,
  required MockWorkoutRepository workouts,
  required MockActiveWorkoutRepository active,
  required MockWorkoutHistoryRepository history,
  required MockExerciseRepository exercises,
  required MockAnnouncementRepository announcements,
}) {
  when(() => auth.currentUser()).thenAnswer((_) async => _user);
  when(() => history.changes).thenAnswer((_) => const Stream<void>.empty());
  when(
    () => workouts.getWorkouts(),
  ).thenAnswer((_) async => [_workout1, _workout2]);
  when(() => active.load()).thenAnswer(
    (_) async => ActiveWorkout(
      id: 'a1',
      workoutId: 'w1',
      workoutName: 'Push Day',
      startedAt: DateTime(2026, 9, 30, 8),
      exercises: const [],
    ),
  );
  when(
    () => history.getHistory(),
  ).thenAnswer((_) async => [_finishedWorkout()]);
  when(
    () => exercises.getExerciseById('e1'),
  ).thenAnswer((_) async => _exercise);
  when(() => exercises.getExercises()).thenAnswer((_) async => [_exercise]);
  when(() => announcements.getAnnouncements()).thenAnswer(
    (_) async => [
      Announcement(
        id: 'a1',
        title: 'New class',
        body: 'HIIT on Mondays',
        date: DateTime(2026, 9, 28),
      ),
    ],
  );
}

void main() {
  group('HomeCubit.load', () {
    test('emits loaded state with assembled dashboard data', () async {
      final auth = MockAuthRepository();
      final workouts = MockWorkoutRepository();
      final active = MockActiveWorkoutRepository();
      final history = MockWorkoutHistoryRepository();
      final exercises = MockExerciseRepository();
      final announcements = MockAnnouncementRepository();
      stubHappyPath(
        auth: auth,
        workouts: workouts,
        active: active,
        history: history,
        exercises: exercises,
        announcements: announcements,
      );
      final cubit = buildCubit(
        auth: auth,
        workouts: workouts,
        active: active,
        history: history,
        exercises: exercises,
        announcements: announcements,
      );

      await cubit.load();
      final state = cubit.state;

      expect(state.status, HomeStatus.loaded);
      expect(state.userName, 'Majid');
      // The beginner member gets the beginner plan, not simply the first.
      expect(state.todayWorkout?.id, 'w2');
      expect(state.hasResumableWorkout, isTrue);
      expect(state.recommended.map((w) => w.id), ['w1']);
      expect(state.recentExercises.map((e) => e.id), ['e1']);
      expect(state.weeklySummary?.totalWorkouts, 1);
      expect(state.announcements, hasLength(1));
      await cubit.close();
    });

    test('falls back to "there" when no user is signed in', () async {
      final auth = MockAuthRepository();
      final workouts = MockWorkoutRepository();
      final active = MockActiveWorkoutRepository();
      final history = MockWorkoutHistoryRepository();
      final exercises = MockExerciseRepository();
      final announcements = MockAnnouncementRepository();
      stubHappyPath(
        auth: auth,
        workouts: workouts,
        active: active,
        history: history,
        exercises: exercises,
        announcements: announcements,
      );
      when(auth.currentUser).thenAnswer((_) async => null);
      final cubit = buildCubit(
        auth: auth,
        workouts: workouts,
        active: active,
        history: history,
        exercises: exercises,
        announcements: announcements,
      );

      await cubit.load();

      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.userName, 'there');
      await cubit.close();
    });

    test('emits error when a source fails', () async {
      final auth = MockAuthRepository();
      final workouts = MockWorkoutRepository();
      final active = MockActiveWorkoutRepository();
      final history = MockWorkoutHistoryRepository();
      final exercises = MockExerciseRepository();
      final announcements = MockAnnouncementRepository();
      stubHappyPath(
        auth: auth,
        workouts: workouts,
        active: active,
        history: history,
        exercises: exercises,
        announcements: announcements,
      );
      when(workouts.getWorkouts).thenThrow(Exception('offline'));
      final cubit = buildCubit(
        auth: auth,
        workouts: workouts,
        active: active,
        history: history,
        exercises: exercises,
        announcements: announcements,
      );

      await cubit.load();

      expect(cubit.state.status, HomeStatus.error);
      expect(cubit.state.errorMessage, isNotNull);
      await cubit.close();
    });
  });
}
