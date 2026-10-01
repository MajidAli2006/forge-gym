import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/progress/domain/usecases/get_progress_summary_usecase.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';

class FakeHistoryRepository implements WorkoutHistoryRepository {
  FakeHistoryRepository(this._history);

  final List<CompletedWorkout> _history;

  @override
  Future<List<CompletedWorkout>> getHistory({int limit = 50}) async =>
      _history.take(limit).toList();

  @override
  Future<void> saveCompleted(CompletedWorkout workout) async {
    _history.insert(0, workout);
  }

  @override
  Future<void> upsertCompleted(CompletedWorkout workout) async {
    final index = _history.indexWhere((w) => w.id == workout.id);
    if (index == -1) {
      _history.insert(0, workout);
    } else {
      _history[index] = workout;
    }
  }

  @override
  Stream<void> get changes => const Stream<void>.empty();
}

CompletedWorkout workoutAt(
  DateTime finishedAt, {
  double volumeKg = 100,
  int durationSeconds = 1800,
}) {
  return CompletedWorkout(
    id: 'w-${finishedAt.toIso8601String()}',
    workoutId: 'workout-1',
    workoutName: 'Push Day',
    startedAt: finishedAt.subtract(Duration(seconds: durationSeconds)),
    finishedAt: finishedAt,
    durationSeconds: durationSeconds,
    totalVolumeKg: volumeKg,
    exercises: const <CompletedExercise>[],
  );
}

void main() {
  // Wednesday 2026-09-30, 10:00 — the week started Monday 2026-09-28.
  final now = DateTime(2026, 9, 30, 10);

  group('GetProgressSummaryUseCase', () {
    test('returns zeros for empty history', () async {
      final useCase = GetProgressSummaryUseCase(FakeHistoryRepository([]));

      final summary = await useCase(now: now);

      expect(summary.workoutsThisWeek, 0);
      expect(summary.currentStreakDays, 0);
      expect(summary.totalWorkouts, 0);
      expect(summary.totalMinutes, 0);
      expect(summary.totalVolumeKg, 0);
    });

    test('counts only workouts since Monday for this week', () async {
      final useCase = GetProgressSummaryUseCase(
        FakeHistoryRepository([
          workoutAt(DateTime(2026, 9, 27, 18)), // Sunday — previous week
          workoutAt(DateTime(2026, 9, 28, 8)), // Monday
          workoutAt(DateTime(2026, 9, 30, 9)), // Wednesday (today)
        ]),
      );

      final summary = await useCase(now: now);

      expect(summary.workoutsThisWeek, 2);
      expect(summary.totalWorkouts, 3);
    });

    test('streak counts consecutive days ending today', () async {
      final useCase = GetProgressSummaryUseCase(
        FakeHistoryRepository([
          workoutAt(DateTime(2026, 9, 28, 8)),
          workoutAt(DateTime(2026, 9, 29, 8)),
          workoutAt(DateTime(2026, 9, 29, 18)), // same day, one streak day
          workoutAt(DateTime(2026, 9, 30, 9)),
        ]),
      );

      final summary = await useCase(now: now);

      expect(summary.currentStreakDays, 3);
    });

    test('streak survives a rest day today', () async {
      final useCase = GetProgressSummaryUseCase(
        FakeHistoryRepository([
          workoutAt(DateTime(2026, 9, 28, 8)),
          workoutAt(DateTime(2026, 9, 29, 8)),
        ]),
      );

      final summary = await useCase(now: now);

      expect(summary.currentStreakDays, 2);
    });

    test('streak breaks on a missed day', () async {
      final useCase = GetProgressSummaryUseCase(
        FakeHistoryRepository([
          workoutAt(DateTime(2026, 9, 26, 8)), // Saturday
          workoutAt(DateTime(2026, 9, 30, 9)), // Wednesday — gap in between
        ]),
      );

      final summary = await useCase(now: now);

      expect(summary.currentStreakDays, 1);
    });

    test('sums duration and volume across history', () async {
      final useCase = GetProgressSummaryUseCase(
        FakeHistoryRepository([
          workoutAt(
            DateTime(2026, 9, 30, 9),
            volumeKg: 1500,
            durationSeconds: 1800,
          ),
          workoutAt(
            DateTime(2026, 9, 29, 9),
            volumeKg: 2500,
            durationSeconds: 3600,
          ),
        ]),
      );

      final summary = await useCase(now: now);

      expect(summary.totalMinutes, 90);
      expect(summary.totalVolumeKg, 4000);
    });
  });
}
