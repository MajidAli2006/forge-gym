import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

/// One logged set in a finished workout.
class PerformedSet extends Equatable {
  const PerformedSet({
    required this.setNumber,
    required this.reps,
    required this.weightKg,
  });

  final int setNumber;
  final int reps;
  final double weightKg;

  @override
  List<Object?> get props => <Object?>[setNumber, reps, weightKg];
}

/// One exercise in a finished workout, with only the completed sets.
class CompletedExercise extends Equatable {
  const CompletedExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.tracking = TrackingType.weightedReps,
  });

  final String exerciseId;
  final String exerciseName;

  /// [PerformedSet.reps] holds seconds when [tracking] is timed.
  final List<PerformedSet> sets;
  final TrackingType tracking;

  @override
  List<Object?> get props => <Object?>[
    exerciseId,
    exerciseName,
    sets,
    tracking,
  ];
}

/// A finished workout, persisted to history. The progress feature reads
/// these through [WorkoutHistoryRepository] to build stats and charts.
class CompletedWorkout extends Equatable {
  const CompletedWorkout({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    required this.finishedAt,
    required this.durationSeconds,
    required this.totalVolumeKg,
    required this.exercises,
  });

  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int durationSeconds;

  /// Sum of reps × weight across completed sets.
  final double totalVolumeKg;

  final List<CompletedExercise> exercises;

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  @override
  List<Object?> get props => <Object?>[
    id,
    workoutId,
    workoutName,
    startedAt,
    finishedAt,
    durationSeconds,
    totalVolumeKg,
    exercises,
  ];
}
