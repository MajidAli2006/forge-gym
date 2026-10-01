import 'package:forge_gym/core/errors/failures.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';

/// Records a single set from an exercise page without a full workout.
///
/// All quick logs from one day share one "Quick log" history entry, so
/// stats, streaks and challenges count the day once rather than once per
/// set. Volume, reps and hold seconds are credited exactly like a planned
/// workout's sets.
class QuickLogSetUseCase {
  const QuickLogSetUseCase(this._history);

  final WorkoutHistoryRepository _history;

  static const String workoutId = 'quick-log';
  static const String workoutName = 'Quick log';

  Future<CompletedWorkout> call({
    required Exercise exercise,
    required int count,
    double weightKg = 0,
    DateTime? now,
  }) async {
    if (count <= 0) {
      throw ValidationFailure(
        exercise.tracking.isTimed
            ? 'Enter how many seconds you held.'
            : 'Enter how many reps you did.',
      );
    }
    if (weightKg < 0 || weightKg > 500) {
      throw const ValidationFailure('Enter a weight between 0 and 500 kg.');
    }
    final at = now ?? DateTime.now();
    final day = DateTime(at.year, at.month, at.day);
    final id = '$workoutId-${day.toIso8601String().substring(0, 10)}';

    final existing = (await _history.getHistory()).firstWhere(
      (w) => w.id == id,
      orElse: () => CompletedWorkout(
        id: id,
        workoutId: workoutId,
        workoutName: workoutName,
        startedAt: at,
        finishedAt: at,
        durationSeconds: 0,
        totalVolumeKg: 0,
        exercises: const <CompletedExercise>[],
      ),
    );

    final exercises = List<CompletedExercise>.of(existing.exercises);
    final index = exercises.indexWhere((e) => e.exerciseId == exercise.id);
    final previous = index == -1 ? null : exercises[index];
    final sets = List<PerformedSet>.of(previous?.sets ?? const <PerformedSet>[])
      ..add(
        PerformedSet(
          setNumber: (previous?.sets.length ?? 0) + 1,
          reps: count,
          weightKg: exercise.tracking.isTimed ? 0 : weightKg,
        ),
      );
    final merged = CompletedExercise(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      sets: sets,
      tracking: exercise.tracking,
    );
    if (index == -1) {
      exercises.add(merged);
    } else {
      exercises[index] = merged;
    }

    // A quick-log "session" spans first to last set of the day; each set
    // is credited a nominal minute so the minutes stat isn't always zero.
    final volumeDelta = exercise.tracking.isTimed ? 0.0 : count * weightKg;
    final updated = CompletedWorkout(
      id: id,
      workoutId: workoutId,
      workoutName: workoutName,
      startedAt: existing.startedAt,
      finishedAt: at,
      durationSeconds: existing.durationSeconds + 60,
      totalVolumeKg: existing.totalVolumeKg + volumeDelta,
      exercises: exercises,
    );
    await _history.upsertCompleted(updated);
    return updated;
  }
}
