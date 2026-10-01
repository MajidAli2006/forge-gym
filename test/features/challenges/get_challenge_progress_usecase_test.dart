import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/challenges/domain/entities/challenge.dart';
import 'package:forge_gym/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:forge_gym/features/challenges/domain/usecases/get_challenge_progress_usecase.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';

class _Challenges implements ChallengeRepository {
  _Challenges(this.items);
  final List<Challenge> items;
  @override
  Future<List<Challenge>> getChallenges() async => items;
}

class _Enrollments implements ChallengeEnrollmentRepository {
  final Map<String, ChallengeEnrollment> store = {};
  int completions = 0;
  @override
  Stream<void> get changes => const Stream.empty();
  @override
  Future<List<ChallengeEnrollment>> getAll() async => store.values.toList();
  @override
  Future<void> join(String challengeId, {required DateTime at}) async {
    store[challengeId] = ChallengeEnrollment(
      challengeId: challengeId,
      joinedAt: at,
    );
  }

  @override
  Future<void> leave(String challengeId) async => store.remove(challengeId);
  @override
  Future<void> markCompleted(String challengeId, {required DateTime at}) async {
    completions++;
    store[challengeId] = store[challengeId]!.copyWith(completedAt: at);
  }
}

class _History implements WorkoutHistoryRepository {
  _History(this.items);
  final List<CompletedWorkout> items;
  @override
  Stream<void> get changes => const Stream.empty();
  @override
  Future<List<CompletedWorkout>> getHistory({int limit = 50}) async => items;
  @override
  Future<void> saveCompleted(CompletedWorkout workout) async {}
  @override
  Future<void> upsertCompleted(CompletedWorkout workout) async {}
}

CompletedWorkout _workout(
  DateTime at, {
  List<CompletedExercise> exercises = const [],
}) => CompletedWorkout(
  id: 'w-${at.toIso8601String()}',
  workoutId: 'plan',
  workoutName: 'Plan',
  startedAt: at.subtract(const Duration(minutes: 30)),
  finishedAt: at,
  durationSeconds: 1800,
  totalVolumeKg: 500,
  exercises: exercises,
);

const _workoutsChallenge = Challenge(
  id: 'first-steps',
  title: 'First Steps',
  tagline: '3 workouts',
  description: '',
  icon: 'flag',
  metric: ChallengeMetric.workouts,
  target: 3,
  durationDays: 14,
  difficulty: Difficulty.beginner,
);

const _pushUps = Challenge(
  id: 'push-up-200',
  title: 'Push-up 200',
  tagline: '',
  description: '',
  icon: 'pushup',
  metric: ChallengeMetric.exerciseReps,
  target: 200,
  durationDays: 14,
  difficulty: Difficulty.beginner,
  exerciseId: 'push-up',
);

void main() {
  final now = DateTime(2026, 9, 30, 12);

  test('unjoined challenges are available with zero progress', () async {
    final useCase = GetChallengeProgressUseCase(
      challenges: _Challenges(const [_workoutsChallenge]),
      enrollments: _Enrollments(),
      history: _History([_workout(now)]),
    );
    final result = await useCase(now: now);
    expect(result.single.status, ChallengeStatus.available);
    expect(result.single.current, 0);
  });

  test('only workouts finished after joining count', () async {
    final enrollments = _Enrollments()
      ..store['first-steps'] = ChallengeEnrollment(
        challengeId: 'first-steps',
        joinedAt: now.subtract(const Duration(days: 2)),
      );
    final useCase = GetChallengeProgressUseCase(
      challenges: _Challenges(const [_workoutsChallenge]),
      enrollments: enrollments,
      history: _History([
        _workout(now.subtract(const Duration(days: 5))), // before joining
        _workout(now.subtract(const Duration(days: 1))),
        _workout(now),
      ]),
    );
    final result = await useCase(now: now);
    expect(result.single.status, ChallengeStatus.active);
    expect(result.single.current, 2);
    expect(result.single.daysLeft, 12);
  });

  test('reaching the target marks the challenge completed once', () async {
    final enrollments = _Enrollments()
      ..store['first-steps'] = ChallengeEnrollment(
        challengeId: 'first-steps',
        joinedAt: now.subtract(const Duration(days: 3)),
      );
    final useCase = GetChallengeProgressUseCase(
      challenges: _Challenges(const [_workoutsChallenge]),
      enrollments: enrollments,
      history: _History([
        _workout(now.subtract(const Duration(days: 2))),
        _workout(now.subtract(const Duration(days: 1))),
        _workout(now),
      ]),
    );
    final first = await useCase(now: now);
    expect(first.single.status, ChallengeStatus.completed);
    expect(enrollments.completions, 1);
    await useCase(now: now);
    expect(enrollments.completions, 1, reason: 'completion is idempotent');
  });

  test('exercise rep challenges sum reps of that exercise only', () async {
    final enrollments = _Enrollments()
      ..store['push-up-200'] = ChallengeEnrollment(
        challengeId: 'push-up-200',
        joinedAt: now.subtract(const Duration(days: 1)),
      );
    final useCase = GetChallengeProgressUseCase(
      challenges: _Challenges(const [_pushUps]),
      enrollments: enrollments,
      history: _History([
        _workout(
          now,
          exercises: const [
            CompletedExercise(
              exerciseId: 'push-up',
              exerciseName: 'Push Up',
              tracking: TrackingType.bodyweightReps,
              sets: [
                PerformedSet(setNumber: 1, reps: 15, weightKg: 0),
                PerformedSet(setNumber: 2, reps: 12, weightKg: 0),
              ],
            ),
            CompletedExercise(
              exerciseId: 'plank',
              exerciseName: 'Plank',
              tracking: TrackingType.timed,
              sets: [PerformedSet(setNumber: 1, reps: 30, weightKg: 0)],
            ),
          ],
        ),
      ]),
    );
    final result = await useCase(now: now);
    expect(result.single.current, 27);
    expect(result.single.status, ChallengeStatus.active);
  });

  test('a joined challenge past its deadline is expired', () async {
    final enrollments = _Enrollments()
      ..store['first-steps'] = ChallengeEnrollment(
        challengeId: 'first-steps',
        joinedAt: now.subtract(const Duration(days: 20)),
      );
    final useCase = GetChallengeProgressUseCase(
      challenges: _Challenges(const [_workoutsChallenge]),
      enrollments: enrollments,
      history: _History(const []),
    );
    final result = await useCase(now: now);
    expect(result.single.status, ChallengeStatus.expired);
    expect(result.single.daysLeft, 0);
  });
}
