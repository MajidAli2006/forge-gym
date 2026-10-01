import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

/// Lifecycle of a live session. `resting` means the rest timer is running
/// after a completed set; the cubit also tracks the countdown itself.
enum ActiveWorkoutStatus { inProgress, resting }

/// One performed set inside a live session.
class ActiveSet extends Equatable {
  const ActiveSet({
    required this.reps,
    required this.weightKg,
    this.completed = false,
  });

  final int reps;
  final double weightKg;
  final bool completed;

  ActiveSet copyWith({int? reps, double? weightKg, bool? completed}) {
    return ActiveSet(
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => <Object?>[reps, weightKg, completed];
}

/// One exercise inside a live session, with its per-set log.
class ActiveExercise extends Equatable {
  const ActiveExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    required this.restSeconds,
    required this.sets,
    this.tracking = TrackingType.weightedReps,
  });

  final String exerciseId;

  /// Denormalized at session start so the session survives library changes.
  final String exerciseName;
  final int targetSets;

  /// Target count per set: reps, or seconds when [tracking] is timed.
  final int targetReps;
  final int restSeconds;
  final List<ActiveSet> sets;
  final TrackingType tracking;

  int get completedSetCount => sets.where((s) => s.completed).length;

  bool get isComplete => completedSetCount >= targetSets;

  /// Index of the first set still to do, or the last set when all are done.
  int get firstIncompleteSetIndex {
    final index = sets.indexWhere((s) => !s.completed);
    return index == -1 ? sets.length - 1 : index;
  }

  /// The most recently completed set, used to prefill the next one.
  ActiveSet? get lastCompletedSet {
    for (final set in sets.reversed) {
      if (set.completed) return set;
    }
    return null;
  }

  ActiveExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    int? targetSets,
    int? targetReps,
    int? restSeconds,
    List<ActiveSet>? sets,
    TrackingType? tracking,
  }) {
    return ActiveExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      restSeconds: restSeconds ?? this.restSeconds,
      sets: sets ?? this.sets,
      tracking: tracking ?? this.tracking,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    exerciseId,
    exerciseName,
    targetSets,
    targetReps,
    restSeconds,
    sets,
    tracking,
  ];
}

/// A workout session in progress. Immutable — every mutation returns a copy
/// so the cubit always emits a new state and persistence stays consistent.
class ActiveWorkout extends Equatable {
  const ActiveWorkout({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    required this.exercises,
    this.currentExerciseIndex = 0,
    this.currentSetIndex = 0,
    this.status = ActiveWorkoutStatus.inProgress,
  });

  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime startedAt;
  final List<ActiveExercise> exercises;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final ActiveWorkoutStatus status;

  ActiveExercise get currentExercise => exercises[currentExerciseIndex];

  ActiveSet get currentSet => currentExercise.sets[currentSetIndex];

  /// Marks the current set complete with the logged reps/weight.
  ActiveWorkout completeCurrentSet({
    required int reps,
    required double weightKg,
  }) {
    final exercise = currentExercise;
    final updatedSets = List<ActiveSet>.of(exercise.sets);
    updatedSets[currentSetIndex] = updatedSets[currentSetIndex].copyWith(
      reps: reps,
      weightKg: weightKg,
      completed: true,
    );
    final updatedExercises = List<ActiveExercise>.of(exercises);
    updatedExercises[currentExerciseIndex] = exercise.copyWith(
      sets: updatedSets,
    );
    return copyWith(
      exercises: updatedExercises,
      status: ActiveWorkoutStatus.resting,
    );
  }

  /// Moves to the next set, or the next exercise, or returns null when the
  /// whole workout is done (the cubit then finishes the session).
  ActiveWorkout? advance() {
    if (currentSetIndex + 1 < currentExercise.targetSets) {
      return copyWith(
        currentSetIndex: currentSetIndex + 1,
        status: ActiveWorkoutStatus.inProgress,
      );
    }
    if (currentExerciseIndex + 1 < exercises.length) {
      return copyWith(
        currentExerciseIndex: currentExerciseIndex + 1,
        currentSetIndex: 0,
        status: ActiveWorkoutStatus.inProgress,
      );
    }
    return null;
  }

  /// Jumps to an exercise (previous/next buttons), landing on its first
  /// unfinished set so completed work is never silently overwritten.
  ActiveWorkout moveToExercise(int index) {
    final clamped = index.clamp(0, exercises.length - 1);
    return copyWith(
      currentExerciseIndex: clamped,
      currentSetIndex: exercises[clamped].firstIncompleteSetIndex,
      status: ActiveWorkoutStatus.inProgress,
    );
  }

  int get completedSetCount =>
      exercises.fold(0, (sum, e) => sum + e.completedSetCount);

  /// Normalizes a restored session: never resume mid-rest after a restart.
  ActiveWorkout normalizedForResume() =>
      copyWith(status: ActiveWorkoutStatus.inProgress);

  ActiveWorkout copyWith({
    String? id,
    String? workoutId,
    String? workoutName,
    DateTime? startedAt,
    List<ActiveExercise>? exercises,
    int? currentExerciseIndex,
    int? currentSetIndex,
    ActiveWorkoutStatus? status,
  }) {
    return ActiveWorkout(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      workoutName: workoutName ?? this.workoutName,
      startedAt: startedAt ?? this.startedAt,
      exercises: exercises ?? this.exercises,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    workoutId,
    workoutName,
    startedAt,
    exercises,
    currentExerciseIndex,
    currentSetIndex,
    status,
  ];
}
