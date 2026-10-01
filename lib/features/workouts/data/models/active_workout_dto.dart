import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/workouts/domain/entities/active_workout.dart';

/// Serialization for the persisted in-progress session
/// (SharedPreferences key `forge.active_session`).
class ActiveSetDto {
  const ActiveSetDto({
    required this.reps,
    required this.weightKg,
    required this.completed,
  });

  factory ActiveSetDto.fromJson(Map<String, dynamic> json) => ActiveSetDto(
    reps: (json['reps'] as num).toInt(),
    weightKg: (json['weightKg'] as num).toDouble(),
    completed: json['completed'] as bool,
  );

  factory ActiveSetDto.fromDomain(ActiveSet entity) => ActiveSetDto(
    reps: entity.reps,
    weightKg: entity.weightKg,
    completed: entity.completed,
  );

  final int reps;
  final double weightKg;
  final bool completed;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'reps': reps,
    'weightKg': weightKg,
    'completed': completed,
  };

  ActiveSet toDomain() =>
      ActiveSet(reps: reps, weightKg: weightKg, completed: completed);
}

class ActiveExerciseDto {
  const ActiveExerciseDto({
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    required this.restSeconds,
    required this.sets,
    this.tracking = TrackingType.weightedReps,
  });

  factory ActiveExerciseDto.fromJson(Map<String, dynamic> json) =>
      ActiveExerciseDto(
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String,
        targetSets: (json['targetSets'] as num).toInt(),
        targetReps: (json['targetReps'] as num).toInt(),
        restSeconds: (json['restSeconds'] as num).toInt(),
        sets: (json['sets'] as List)
            .map((e) => ActiveSetDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        tracking: _tracking(json['tracking'] as String?),
      );

  /// Snapshots written before tracking types existed default to weighted.
  static TrackingType _tracking(String? name) => TrackingType.values.firstWhere(
    (t) => t.name == name,
    orElse: () => TrackingType.weightedReps,
  );

  factory ActiveExerciseDto.fromDomain(ActiveExercise entity) =>
      ActiveExerciseDto(
        exerciseId: entity.exerciseId,
        exerciseName: entity.exerciseName,
        targetSets: entity.targetSets,
        targetReps: entity.targetReps,
        restSeconds: entity.restSeconds,
        sets: entity.sets.map(ActiveSetDto.fromDomain).toList(),
        tracking: entity.tracking,
      );

  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final int restSeconds;
  final List<ActiveSetDto> sets;
  final TrackingType tracking;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'targetSets': targetSets,
    'targetReps': targetReps,
    'restSeconds': restSeconds,
    'sets': sets.map((s) => s.toJson()).toList(),
    'tracking': tracking.name,
  };

  ActiveExercise toDomain() => ActiveExercise(
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    targetSets: targetSets,
    targetReps: targetReps,
    restSeconds: restSeconds,
    sets: sets.map((s) => s.toDomain()).toList(),
    tracking: tracking,
  );
}

class ActiveWorkoutDto {
  const ActiveWorkoutDto({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.currentSetIndex,
    required this.status,
  });

  factory ActiveWorkoutDto.fromJson(Map<String, dynamic> json) =>
      ActiveWorkoutDto(
        id: json['id'] as String,
        workoutId: json['workoutId'] as String,
        workoutName: json['workoutName'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        exercises: (json['exercises'] as List)
            .map((e) => ActiveExerciseDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentExerciseIndex: (json['currentExerciseIndex'] as num).toInt(),
        currentSetIndex: (json['currentSetIndex'] as num).toInt(),
        status: ActiveWorkoutStatus.values.byName(json['status'] as String),
      );

  factory ActiveWorkoutDto.fromDomain(ActiveWorkout entity) => ActiveWorkoutDto(
    id: entity.id,
    workoutId: entity.workoutId,
    workoutName: entity.workoutName,
    startedAt: entity.startedAt,
    exercises: entity.exercises.map(ActiveExerciseDto.fromDomain).toList(),
    currentExerciseIndex: entity.currentExerciseIndex,
    currentSetIndex: entity.currentSetIndex,
    status: entity.status,
  );

  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime startedAt;
  final List<ActiveExerciseDto> exercises;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final ActiveWorkoutStatus status;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'workoutId': workoutId,
    'workoutName': workoutName,
    'startedAt': startedAt.toIso8601String(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'currentExerciseIndex': currentExerciseIndex,
    'currentSetIndex': currentSetIndex,
    'status': status.name,
  };

  ActiveWorkout toDomain() => ActiveWorkout(
    id: id,
    workoutId: workoutId,
    workoutName: workoutName,
    startedAt: startedAt,
    exercises: exercises.map((e) => e.toDomain()).toList(),
    currentExerciseIndex: currentExerciseIndex,
    currentSetIndex: currentSetIndex,
    status: status,
  );
}
