import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

/// One exercise inside a workout plan, with its prescription.
class WorkoutExercise extends Equatable {
  const WorkoutExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.order,
  });

  final String exerciseId;
  final int sets;
  final int reps;

  /// Rest between sets, in seconds.
  final int restSeconds;

  /// Position inside the workout (0-based).
  final int order;

  @override
  List<Object?> get props => <Object?>[
    exerciseId,
    sets,
    reps,
    restSeconds,
    order,
  ];
}

/// A workout plan: an ordered list of exercises with prescriptions.
///
/// Pure domain object — no JSON, no Flutter. The [Exercise] details
/// (name, demo video…) are resolved via `ExerciseRepository` when needed.
class Workout extends Equatable {
  const Workout({
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

  final String id;
  final String name;
  final String description;
  final Difficulty difficulty;
  final int durationMinutes;
  final List<MuscleGroup> targetMuscles;
  final List<WorkoutExercise> exercises;

  /// Optional bundled header art. Null = gradient/icon header in UI.
  final String? imageAsset;

  /// True for routines the member built themselves (editable, deletable).
  final bool isCustom;

  int get exerciseCount => exercises.length;

  Workout copyWith({
    String? id,
    String? name,
    String? description,
    Difficulty? difficulty,
    int? durationMinutes,
    List<MuscleGroup>? targetMuscles,
    List<WorkoutExercise>? exercises,
    String? imageAsset,
    bool? isCustom,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      exercises: exercises ?? this.exercises,
      imageAsset: imageAsset ?? this.imageAsset,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    description,
    difficulty,
    durationMinutes,
    targetMuscles,
    exercises,
    imageAsset,
    isCustom,
  ];
}
