import 'package:forge_gym/features/challenges/domain/entities/challenge.dart';
import 'package:forge_gym/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';

/// Joins the challenge catalogue with the member's enrollments and finished
/// workouts to produce live progress for every challenge.
///
/// A challenge that reaches its target is marked completed in the
/// enrollment store so the badge survives even if history is trimmed.
class GetChallengeProgressUseCase {
  const GetChallengeProgressUseCase({
    required ChallengeRepository challenges,
    required ChallengeEnrollmentRepository enrollments,
    required WorkoutHistoryRepository history,
  }) : _challenges = challenges,
       _enrollments = enrollments,
       _history = history;

  final ChallengeRepository _challenges;
  final ChallengeEnrollmentRepository _enrollments;
  final WorkoutHistoryRepository _history;

  Future<List<ChallengeProgress>> call({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final catalogue = await _challenges.getChallenges();
    final enrollments = {
      for (final e in await _enrollments.getAll()) e.challengeId: e,
    };
    final history = await _history.getHistory(limit: 200);

    final result = <ChallengeProgress>[];
    for (final challenge in catalogue) {
      final enrollment = enrollments[challenge.id];
      if (enrollment == null) {
        result.add(
          ChallengeProgress(
            challenge: challenge,
            status: ChallengeStatus.available,
            current: 0,
            now: current,
          ),
        );
        continue;
      }
      final end = enrollment.joinedAt.add(
        Duration(days: challenge.durationDays),
      );
      final windowEnd = enrollment.completedAt ?? end;
      final inWindow = history
          .where(
            (w) =>
                !w.finishedAt.isBefore(enrollment.joinedAt) &&
                !w.finishedAt.isAfter(windowEnd),
          )
          .toList();
      final value = _measure(challenge, inWindow, current, enrollment.joinedAt);

      var status = ChallengeStatus.active;
      var resolved = enrollment;
      if (enrollment.completedAt != null) {
        status = ChallengeStatus.completed;
      } else if (value >= challenge.target) {
        status = ChallengeStatus.completed;
        resolved = enrollment.copyWith(completedAt: current);
        await _enrollments.markCompleted(challenge.id, at: current);
      } else if (current.isAfter(end)) {
        status = ChallengeStatus.expired;
      }
      result.add(
        ChallengeProgress(
          challenge: challenge,
          status: status,
          current: value,
          enrollment: resolved,
          now: current,
        ),
      );
    }
    return result;
  }

  static int _measure(
    Challenge challenge,
    List<CompletedWorkout> workouts,
    DateTime now,
    DateTime joinedAt,
  ) {
    switch (challenge.metric) {
      case ChallengeMetric.workouts:
        return workouts.length;
      case ChallengeMetric.minutes:
        return workouts.fold<int>(0, (sum, w) => sum + w.durationSeconds) ~/ 60;
      case ChallengeMetric.volumeKg:
        return workouts
            .fold<double>(0, (sum, w) => sum + w.totalVolumeKg)
            .round();
      case ChallengeMetric.exerciseReps:
      case ChallengeMetric.holdSeconds:
        var total = 0;
        for (final workout in workouts) {
          for (final exercise in workout.exercises) {
            if (exercise.exerciseId != challenge.exerciseId) continue;
            final timed = exercise.tracking.isTimed;
            if (timed != (challenge.metric == ChallengeMetric.holdSeconds)) {
              continue;
            }
            total += exercise.sets.fold<int>(0, (sum, s) => sum + s.reps);
          }
        }
        return total;
      case ChallengeMetric.streakDays:
        final days = workouts
            .map(
              (w) => DateTime(
                w.finishedAt.year,
                w.finishedAt.month,
                w.finishedAt.day,
              ),
            )
            .toSet();
        final joinedDay = DateTime(joinedAt.year, joinedAt.month, joinedAt.day);
        var cursor = DateTime(now.year, now.month, now.day);
        if (!days.contains(cursor)) {
          cursor = cursor.subtract(const Duration(days: 1));
        }
        var streak = 0;
        while (days.contains(cursor) && !cursor.isBefore(joinedDay)) {
          streak++;
          cursor = cursor.subtract(const Duration(days: 1));
        }
        return streak;
    }
  }
}
