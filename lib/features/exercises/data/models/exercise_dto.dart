/// Transport object for exercise JSON (local mock file today, API tomorrow).
///
/// Enums travel as their `.name` strings; lists as JSON arrays. UI code never
/// sees this class — the mapper converts it to the domain [Exercise].
class ExerciseDto {
  const ExerciseDto({
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
    this.tracking,
  });

  factory ExerciseDto.fromJson(Map<String, dynamic> json) {
    List<String> stringList(String key) =>
        (json[key] as List<dynamic>).map((e) => e as String).toList();

    return ExerciseDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      instructions: stringList('instructions'),
      primaryMuscles: stringList('primaryMuscles'),
      secondaryMuscles: stringList('secondaryMuscles'),
      equipment: json['equipment'] as String,
      difficulty: json['difficulty'] as String,
      thumbnailAsset: json['thumbnailAsset'] as String,
      videoAsset: json['videoAsset'] as String?,
      commonMistakes: stringList('commonMistakes'),
      tips: stringList('tips'),
      defaultSets: (json['defaultSets'] as num).toInt(),
      defaultReps: (json['defaultReps'] as num).toInt(),
      defaultRestSeconds: (json['defaultRestSeconds'] as num).toInt(),
      tracking: json['tracking'] as String?,
    );
  }

  final String id;
  final String name;
  final String description;
  final List<String> instructions;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String equipment;
  final String difficulty;
  final String thumbnailAsset;
  final String? videoAsset;
  final List<String> commonMistakes;
  final List<String> tips;
  final int defaultSets;
  final int defaultReps;
  final int defaultRestSeconds;

  /// `weightedReps` | `bodyweightReps` | `timed`. Null = infer from
  /// equipment (bodyweight → bodyweightReps, otherwise weightedReps).
  final String? tracking;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'description': description,
    'instructions': instructions,
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': secondaryMuscles,
    'equipment': equipment,
    'difficulty': difficulty,
    'thumbnailAsset': thumbnailAsset,
    'videoAsset': videoAsset,
    'commonMistakes': commonMistakes,
    'tips': tips,
    'defaultSets': defaultSets,
    'defaultReps': defaultReps,
    'defaultRestSeconds': defaultRestSeconds,
    if (tracking != null) 'tracking': tracking,
  };
}
