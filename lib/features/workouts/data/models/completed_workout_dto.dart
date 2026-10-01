import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';

/// Serialization for finished workouts
/// (SharedPreferences key `forge.workout_history`, newest first).
class PerformedSetDto {
  const PerformedSetDto({
    required this.setNumber,
    required this.reps,
    required this.weightKg,
  });

  factory PerformedSetDto.fromJson(Map<String, dynamic> json) =>
      PerformedSetDto(
        setNumber: (json['setNumber'] as num).toInt(),
        reps: (json['reps'] as num).toInt(),
        weightKg: (json['weightKg'] as num).toDouble(),
      );

  factory PerformedSetDto.fromDomain(PerformedSet entity) => PerformedSetDto(
    setNumber: entity.setNumber,
    reps: entity.reps,
    weightKg: entity.weightKg,
  );

  final int setNumber;
  final int reps;
  final double weightKg;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'setNumber': setNumber,
    'reps': reps,
    'weightKg': weightKg,
  };

  PerformedSet toDomain() =>
      PerformedSet(setNumber: setNumber, reps: reps, weightKg: weightKg);
}

class CompletedExerciseDto {
  const CompletedExerciseDto({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.tracking = TrackingType.weightedReps,
  });

  factory CompletedExerciseDto.fromJson(Map<String, dynamic> json) =>
      CompletedExerciseDto(
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String,
        sets: (json['sets'] as List)
            .map((e) => PerformedSetDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        tracking: TrackingType.values.firstWhere(
          (t) => t.name == json['tracking'],
          orElse: () => TrackingType.weightedReps,
        ),
      );

  factory CompletedExerciseDto.fromDomain(CompletedExercise entity) =>
      CompletedExerciseDto(
        exerciseId: entity.exerciseId,
        exerciseName: entity.exerciseName,
        sets: entity.sets.map(PerformedSetDto.fromDomain).toList(),
        tracking: entity.tracking,
      );

  final String exerciseId;
  final String exerciseName;
  final List<PerformedSetDto> sets;
  final TrackingType tracking;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'sets': sets.map((s) => s.toJson()).toList(),
    'tracking': tracking.name,
  };

  CompletedExercise toDomain() => CompletedExercise(
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    sets: sets.map((s) => s.toDomain()).toList(),
    tracking: tracking,
  );
}

class CompletedWorkoutDto {
  const CompletedWorkoutDto({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    required this.finishedAt,
    required this.durationSeconds,
    required this.totalVolumeKg,
    required this.exercises,
  });

  factory CompletedWorkoutDto.fromJson(Map<String, dynamic> json) =>
      CompletedWorkoutDto(
        id: json['id'] as String,
        workoutId: json['workoutId'] as String,
        workoutName: json['workoutName'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: DateTime.parse(json['finishedAt'] as String),
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        totalVolumeKg: (json['totalVolumeKg'] as num).toDouble(),
        exercises: (json['exercises'] as List)
            .map(
              (e) => CompletedExerciseDto.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );

  factory CompletedWorkoutDto.fromDomain(CompletedWorkout entity) =>
      CompletedWorkoutDto(
        id: entity.id,
        workoutId: entity.workoutId,
        workoutName: entity.workoutName,
        startedAt: entity.startedAt,
        finishedAt: entity.finishedAt,
        durationSeconds: entity.durationSeconds,
        totalVolumeKg: entity.totalVolumeKg,
        exercises: entity.exercises
            .map(CompletedExerciseDto.fromDomain)
            .toList(),
      );

  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int durationSeconds;
  final double totalVolumeKg;
  final List<CompletedExerciseDto> exercises;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'workoutId': workoutId,
    'workoutName': workoutName,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'totalVolumeKg': totalVolumeKg,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  CompletedWorkout toDomain() => CompletedWorkout(
    id: id,
    workoutId: workoutId,
    workoutName: workoutName,
    startedAt: startedAt,
    finishedAt: finishedAt,
    durationSeconds: durationSeconds,
    totalVolumeKg: totalVolumeKg,
    exercises: exercises.map((e) => e.toDomain()).toList(),
  );
}
