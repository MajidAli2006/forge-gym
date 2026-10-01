import 'package:forge_gym/features/exercises/data/models/exercise_dto.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

/// Converts between [ExerciseDto] (data layer) and [Exercise] (domain).
/// Unknown enum names from JSON fall back to safe defaults rather than
/// throwing, so one bad row can't break the whole library.
class ExerciseMapper {
  const ExerciseMapper();

  Exercise toDomain(ExerciseDto dto) {
    final equipment = _toEquipment(dto.equipment);
    return Exercise(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      instructions: List<String>.unmodifiable(dto.instructions),
      primaryMuscles: dto.primaryMuscles.map(_toMuscleGroup).toList(),
      secondaryMuscles: dto.secondaryMuscles.map(_toMuscleGroup).toList(),
      equipment: equipment,
      difficulty: _toDifficulty(dto.difficulty),
      thumbnailAsset: dto.thumbnailAsset,
      videoAsset: dto.videoAsset,
      commonMistakes: List<String>.unmodifiable(dto.commonMistakes),
      tips: List<String>.unmodifiable(dto.tips),
      defaultSets: dto.defaultSets,
      defaultReps: dto.defaultReps,
      defaultRestSeconds: dto.defaultRestSeconds,
      tracking: _toTracking(dto.tracking, equipment),
    );
  }

  ExerciseDto toDto(Exercise exercise) {
    return ExerciseDto(
      id: exercise.id,
      name: exercise.name,
      description: exercise.description,
      instructions: exercise.instructions,
      primaryMuscles: exercise.primaryMuscles.map((m) => m.name).toList(),
      secondaryMuscles: exercise.secondaryMuscles.map((m) => m.name).toList(),
      equipment: exercise.equipment.name,
      difficulty: exercise.difficulty.name,
      thumbnailAsset: exercise.thumbnailAsset,
      videoAsset: exercise.videoAsset,
      commonMistakes: exercise.commonMistakes,
      tips: exercise.tips,
      defaultSets: exercise.defaultSets,
      defaultReps: exercise.defaultReps,
      defaultRestSeconds: exercise.defaultRestSeconds,
      tracking: exercise.tracking.name,
    );
  }

  TrackingType _toTracking(String? name, Equipment equipment) {
    for (final value in TrackingType.values) {
      if (value.name == name) return value;
    }
    return equipment == Equipment.bodyweight
        ? TrackingType.bodyweightReps
        : TrackingType.weightedReps;
  }

  MuscleGroup _toMuscleGroup(String name) {
    for (final value in MuscleGroup.values) {
      if (value.name == name) return value;
    }
    return MuscleGroup.fullBody;
  }

  Equipment _toEquipment(String name) {
    for (final value in Equipment.values) {
      if (value.name == name) return value;
    }
    return Equipment.bodyweight;
  }

  Difficulty _toDifficulty(String name) {
    for (final value in Difficulty.values) {
      if (value.name == name) return value;
    }
    return Difficulty.beginner;
  }
}
