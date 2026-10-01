import 'package:forge_gym/core/errors/failures.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/custom_workout_repository.dart';

/// Validates and stores a member-built routine.
///
/// Derived fields (target muscles, estimated duration, difficulty) are
/// computed here from the chosen exercises so the editor only collects
/// what the member actually decides: a name, notes, and the prescription.
class SaveCustomWorkoutUseCase {
  const SaveCustomWorkoutUseCase(this._custom, this._exercises);

  final CustomWorkoutRepository _custom;
  final ExerciseRepository _exercises;

  static const int maxExercises = 15;

  Future<Workout> call({
    String? id,
    required String name,
    String description = '',
    required List<WorkoutExercise> exercises,
    DateTime? now,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationFailure('Give your routine a name.');
    }
    if (trimmed.length > 40) {
      throw const ValidationFailure('Keep the name under 40 characters.');
    }
    if (exercises.isEmpty) {
      throw const ValidationFailure('Add at least one exercise.');
    }
    if (exercises.length > maxExercises) {
      throw const ValidationFailure(
        'A routine can have up to $maxExercises exercises.',
      );
    }
    for (final item in exercises) {
      if (item.sets < 1 || item.sets > 10) {
        throw const ValidationFailure('Sets must be between 1 and 10.');
      }
      if (item.reps < 1 || item.reps > 600) {
        throw const ValidationFailure('Reps (or seconds) must be 1 to 600.');
      }
      if (item.restSeconds < 0 || item.restSeconds > 600) {
        throw const ValidationFailure('Rest must be between 0 and 600 s.');
      }
    }

    final resolved = <Exercise>[];
    for (final item in exercises) {
      final exercise = await _exercises.getExerciseById(item.exerciseId);
      if (exercise == null) {
        throw ValidationFailure(
          'One of the exercises (${item.exerciseId}) no longer exists.',
        );
      }
      resolved.add(exercise);
    }

    final ordered = <WorkoutExercise>[
      for (var i = 0; i < exercises.length; i++)
        WorkoutExercise(
          exerciseId: exercises[i].exerciseId,
          sets: exercises[i].sets,
          reps: exercises[i].reps,
          restSeconds: exercises[i].restSeconds,
          order: i,
        ),
    ];

    final workout = Workout(
      id: id ?? 'custom-${(now ?? DateTime.now()).microsecondsSinceEpoch}',
      name: trimmed,
      description: description.trim(),
      difficulty: _difficulty(resolved),
      durationMinutes: _estimateMinutes(ordered, resolved),
      targetMuscles: _targetMuscles(resolved),
      exercises: ordered,
      isCustom: true,
    );
    await _custom.save(workout);
    return workout;
  }

  /// Hardest exercise sets the routine's level.
  static Difficulty _difficulty(List<Exercise> exercises) => exercises
      .map((e) => e.difficulty)
      .reduce((a, b) => a.index >= b.index ? a : b);

  /// Primary muscles in first-seen order, at most five.
  static List<MuscleGroup> _targetMuscles(List<Exercise> exercises) {
    final seen = <MuscleGroup>[];
    for (final exercise in exercises) {
      for (final muscle in exercise.primaryMuscles) {
        if (!seen.contains(muscle)) seen.add(muscle);
      }
    }
    return seen.take(5).toList();
  }

  /// ~40 s of work per set (or the hold itself) plus the rest between
  /// sets, rounded up to 5 minutes.
  static int _estimateMinutes(
    List<WorkoutExercise> items,
    List<Exercise> resolved,
  ) {
    var seconds = 0;
    for (var i = 0; i < items.length; i++) {
      final work = resolved[i].tracking.isTimed ? items[i].reps : 40;
      seconds += items[i].sets * (work + items[i].restSeconds);
    }
    final minutes = (seconds / 60).ceil();
    return ((minutes + 4) ~/ 5) * 5;
  }
}
