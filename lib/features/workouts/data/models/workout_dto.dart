import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';

/// Serialization for `assets/mock/workouts.json`. UI never sees this class —
/// [toDomain] is the mapper step into the domain layer.
class WorkoutExerciseDto {
  const WorkoutExerciseDto({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.order,
  });

  factory WorkoutExerciseDto.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseDto(
      exerciseId: json['exerciseId'] as String,
      sets: (json['sets'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      restSeconds: (json['restSeconds'] as num).toInt(),
      order: (json['order'] as num).toInt(),
    );
  }

  factory WorkoutExerciseDto.fromDomain(WorkoutExercise entity) {
    return WorkoutExerciseDto(
      exerciseId: entity.exerciseId,
      sets: entity.sets,
      reps: entity.reps,
      restSeconds: entity.restSeconds,
      order: entity.order,
    );
  }

  final String exerciseId;
  final int sets;
  final int reps;
  final int restSeconds;
  final int order;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'exerciseId': exerciseId,
    'sets': sets,
    'reps': reps,
    'restSeconds': restSeconds,
    'order': order,
  };

  WorkoutExercise toDomain() => WorkoutExercise(
    exerciseId: exerciseId,
    sets: sets,
    reps: reps,
    restSeconds: restSeconds,
    order: order,
  );
}

class WorkoutDto {
  const WorkoutDto({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.durationMinutes,
    required this.targetMuscles,
    required this.exercises,
    this.imageAsset,
    this.isCustom = false,
  });

  factory WorkoutDto.fromJson(Map<String, dynamic> json) {
    return WorkoutDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      difficulty: Difficulty.values.byName(json['difficulty'] as String),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      targetMuscles: (json['targetMuscles'] as List)
          .map((e) => MuscleGroup.values.byName(e as String))
          .toList(),
      exercises: (json['exercises'] as List)
          .map((e) => WorkoutExerciseDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageAsset: json['imageAsset'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  factory WorkoutDto.fromDomain(Workout entity) {
    return WorkoutDto(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      difficulty: entity.difficulty,
      durationMinutes: entity.durationMinutes,
      targetMuscles: entity.targetMuscles,
      exercises: entity.exercises.map(WorkoutExerciseDto.fromDomain).toList(),
      imageAsset: entity.imageAsset,
      isCustom: entity.isCustom,
    );
  }

  final String id;
  final String name;
  final String description;
  final Difficulty difficulty;
  final int durationMinutes;
  final List<MuscleGroup> targetMuscles;
  final List<WorkoutExerciseDto> exercises;
  final String? imageAsset;
  final bool isCustom;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'description': description,
    'difficulty': difficulty.name,
    'durationMinutes': durationMinutes,
    'targetMuscles': targetMuscles.map((m) => m.name).toList(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
    if (imageAsset != null) 'imageAsset': imageAsset,
    if (isCustom) 'isCustom': true,
  };

  Workout toDomain() => Workout(
    id: id,
    name: name,
    description: description,
    difficulty: difficulty,
    durationMinutes: durationMinutes,
    targetMuscles: targetMuscles,
    exercises: exercises.map((e) => e.toDomain()).toList()
      ..sort((a, b) => a.order.compareTo(b.order)),
    imageAsset: imageAsset,
    isCustom: isCustom,
  );
}
