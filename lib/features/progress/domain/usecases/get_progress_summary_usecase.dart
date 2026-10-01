import 'package:forge_gym/features/progress/domain/entities/progress_summary.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';

/// Computes dashboard statistics from finished workouts.
///
/// The optional [now] parameter exists for tests — production callers omit it.
class GetProgressSummaryUseCase {
  const GetProgressSummaryUseCase(this._historyRepository);

  final WorkoutHistoryRepository _historyRepository;

  Future<ProgressSummary> call({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final history = await _historyRepository.getHistory();

    final weekStart = _startOfWeek(current);
    final workoutsThisWeek = history
        .where((w) => !w.finishedAt.isBefore(weekStart))
        .length;
    final totalWorkouts = history.length;
    final totalSeconds = history.fold<int>(
      0,
      (sum, w) => sum + w.durationSeconds,
    );
    final totalVolumeKg = history.fold<double>(
      0,
      (sum, w) => sum + w.totalVolumeKg,
    );

    return ProgressSummary(
      workoutsThisWeek: workoutsThisWeek,
      currentStreakDays: _streakDays(history, current),
      totalWorkouts: totalWorkouts,
      totalMinutes: totalSeconds ~/ 60,
      totalVolumeKg: totalVolumeKg,
    );
  }

  /// Monday 00:00 of the week containing [day].
  static DateTime _startOfWeek(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Consecutive days (ending today, or yesterday when today is rest)
  /// with at least one finished workout.
  static int _streakDays(List<CompletedWorkout> history, DateTime now) {
    if (history.isEmpty) return 0;
    final activeDays = history
        .map(
          (w) =>
              DateTime(w.finishedAt.year, w.finishedAt.month, w.finishedAt.day),
        )
        .toSet();
    var cursor = DateTime(now.year, now.month, now.day);
    if (!activeDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (activeDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
