import 'package:forge_gym/features/challenges/domain/entities/challenge.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

/// JSON shape of one row in `assets/mock/challenges.json`.
class ChallengeDto {
  const ChallengeDto({
    required this.id,
    required this.title,
    required this.tagline,
    required this.description,
    required this.icon,
    required this.metric,
    required this.target,
    required this.durationDays,
    required this.difficulty,
    this.exerciseId,
    this.exerciseName,
  });

  factory ChallengeDto.fromJson(Map<String, dynamic> json) => ChallengeDto(
    id: json['id'] as String,
    title: json['title'] as String,
    tagline: json['tagline'] as String,
    description: json['description'] as String,
    icon: json['icon'] as String? ?? 'flag',
    metric: json['metric'] as String,
    target: (json['target'] as num).toInt(),
    durationDays: (json['durationDays'] as num).toInt(),
    difficulty: json['difficulty'] as String? ?? 'beginner',
    exerciseId: json['exerciseId'] as String?,
    exerciseName: json['exerciseName'] as String?,
  );

  final String id;
  final String title;
  final String tagline;
  final String description;
  final String icon;
  final String metric;
  final int target;
  final int durationDays;
  final String difficulty;
  final String? exerciseId;
  final String? exerciseName;

  Challenge toDomain() => Challenge(
    id: id,
    title: title,
    tagline: tagline,
    description: description,
    icon: icon,
    metric: ChallengeMetric.values.firstWhere(
      (m) => m.name == metric,
      orElse: () => ChallengeMetric.workouts,
    ),
    target: target,
    durationDays: durationDays,
    difficulty: Difficulty.values.firstWhere(
      (d) => d.name == difficulty,
      orElse: () => Difficulty.beginner,
    ),
    exerciseId: exerciseId,
    exerciseName: exerciseName,
  );
}
