import 'package:equatable/equatable.dart';

/// Target body area of an exercise.
enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  legs,
  glutes,
  core,
  cardio,
  fullBody,
}

/// Equipment required to perform an exercise.
enum Equipment {
  dumbbell,
  barbell,
  cable,
  machine,
  bodyweight,
  kettlebell,
  resistanceBand,
  treadmill,
}

/// Relative intensity of an exercise.
enum Difficulty { beginner, intermediate, advanced }

/// How a set of this exercise is logged during a workout.
///
/// - [weightedReps]: reps at a load (barbell, dumbbell, cable, machine).
/// - [bodyweightReps]: reps only; extra load is optional (weighted pull-up).
/// - [timed]: a hold or interval measured in seconds (plank).
enum TrackingType { weightedReps, bodyweightReps, timed }

extension TrackingTypeLabel on TrackingType {
  /// `12 reps`, `30 s hold` — the unit for a target or logged count.
  String countLabel(int count) => switch (this) {
    TrackingType.timed => '$count s hold',
    TrackingType.weightedReps ||
    TrackingType.bodyweightReps => '$count rep${count == 1 ? '' : 's'}',
  };

  bool get isTimed => this == TrackingType.timed;
  bool get usesWeight => this == TrackingType.weightedReps;
}

/// Human-readable labels for the filter/display enums.
extension MuscleGroupLabel on MuscleGroup {
  String get label => switch (this) {
    MuscleGroup.chest => 'Chest',
    MuscleGroup.back => 'Back',
    MuscleGroup.shoulders => 'Shoulders',
    MuscleGroup.biceps => 'Biceps',
    MuscleGroup.triceps => 'Triceps',
    MuscleGroup.legs => 'Legs',
    MuscleGroup.glutes => 'Glutes',
    MuscleGroup.core => 'Core',
    MuscleGroup.cardio => 'Cardio',
    MuscleGroup.fullBody => 'Full Body',
  };
}

extension EquipmentLabel on Equipment {
  String get label => switch (this) {
    Equipment.dumbbell => 'Dumbbell',
    Equipment.barbell => 'Barbell',
    Equipment.cable => 'Cable',
    Equipment.machine => 'Machine',
    Equipment.bodyweight => 'Bodyweight',
    Equipment.kettlebell => 'Kettlebell',
    Equipment.resistanceBand => 'Resistance Band',
    Equipment.treadmill => 'Treadmill',
  };
}

extension DifficultyLabel on Difficulty {
  String get label => switch (this) {
    Difficulty.beginner => 'Beginner',
    Difficulty.intermediate => 'Intermediate',
    Difficulty.advanced => 'Advanced',
  };
}

/// A single exercise in the library.
///
/// Pure domain object — no JSON, no Flutter. Media is referenced by asset
/// path so the app ships offline-capable demo content; a future API-backed
/// repository can supply remote URLs through the same fields.
class Exercise extends Equatable {
  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.instructions,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipment,
    required this.difficulty,
    required this.thumbnailAsset,
    this.videoAsset,
    required this.commonMistakes,
    required this.tips,
    required this.defaultSets,
    required this.defaultReps,
    required this.defaultRestSeconds,
    this.tracking = TrackingType.weightedReps,
  });

  final String id;
  final String name;
  final String description;

  /// Ordered, written steps. Always present — videos are never the only
  /// source of instruction (accessibility + offline requirement).
  final List<String> instructions;

  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final Equipment equipment;
  final Difficulty difficulty;

  /// Local asset path, e.g. `assets/exercises/bicep-curl-dumbbell/thumb.jpg`.
  final String thumbnailAsset;

  /// Relative media path of the short demo clip, e.g.
  /// `exercises/plank/demo.mp4`, downloaded on demand through `MediaCache`;
  /// null when only a thumbnail is available (UI falls back to the
  /// thumbnail + written steps).
  final String? videoAsset;

  final List<String> commonMistakes;
  final List<String> tips;

  final int defaultSets;

  /// Target count per set: reps, or seconds when [tracking] is timed.
  final int defaultReps;

  /// Suggested rest between sets, in seconds.
  final int defaultRestSeconds;

  final TrackingType tracking;

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? instructions,
    List<MuscleGroup>? primaryMuscles,
    List<MuscleGroup>? secondaryMuscles,
    Equipment? equipment,
    Difficulty? difficulty,
    String? thumbnailAsset,
    String? videoAsset,
    List<String>? commonMistakes,
    List<String>? tips,
    int? defaultSets,
    int? defaultReps,
    int? defaultRestSeconds,
    TrackingType? tracking,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      thumbnailAsset: thumbnailAsset ?? this.thumbnailAsset,
      videoAsset: videoAsset ?? this.videoAsset,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      tips: tips ?? this.tips,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      tracking: tracking ?? this.tracking,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    instructions,
    primaryMuscles,
    secondaryMuscles,
    equipment,
    difficulty,
    thumbnailAsset,
    videoAsset,
    commonMistakes,
    tips,
    defaultSets,
    defaultReps,
    defaultRestSeconds,
    tracking,
  ];
}
