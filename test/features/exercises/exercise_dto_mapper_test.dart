import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/exercises/data/mappers/exercise_mapper.dart';
import 'package:forge_gym/features/exercises/data/models/exercise_dto.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

void main() {
  const mapper = ExerciseMapper();

  ExerciseDto sampleDto() => const ExerciseDto(
    id: 'bicep-curl-dumbbell',
    name: 'Dumbbell Bicep Curl',
    description: 'Classic arm builder.',
    instructions: ['Curl up', 'Lower down'],
    primaryMuscles: ['biceps'],
    secondaryMuscles: ['shoulders'],
    equipment: 'dumbbell',
    difficulty: 'beginner',
    thumbnailAsset: 'assets/exercises/bicep-curl-dumbbell/thumb.jpg',
    videoAsset: 'assets/exercises/bicep-curl-dumbbell/demo.mp4',
    commonMistakes: ['Swinging'],
    tips: ['Control the negative'],
    defaultSets: 3,
    defaultReps: 12,
    defaultRestSeconds: 60,
  );

  group('ExerciseDto', () {
    test('fromJson parses all fields', () {
      final dto = ExerciseDto.fromJson(<String, dynamic>{
        'id': 'x',
        'name': 'X',
        'description': 'd',
        'instructions': ['a'],
        'primaryMuscles': ['chest'],
        'secondaryMuscles': <String>[],
        'equipment': 'barbell',
        'difficulty': 'advanced',
        'thumbnailAsset': 't.jpg',
        'videoAsset': null,
        'commonMistakes': <String>[],
        'tips': <String>[],
        'defaultSets': 4,
        'defaultReps': 8,
        'defaultRestSeconds': 120,
      });

      expect(dto.id, 'x');
      expect(dto.equipment, 'barbell');
      expect(dto.videoAsset, isNull);
      expect(dto.defaultSets, 4);
    });

    test('toJson round-trips through fromJson', () {
      final dto = sampleDto();
      final restored = ExerciseDto.fromJson(dto.toJson());

      expect(restored.id, dto.id);
      expect(restored.name, dto.name);
      expect(restored.instructions, dto.instructions);
      expect(restored.primaryMuscles, dto.primaryMuscles);
      expect(restored.videoAsset, dto.videoAsset);
      expect(restored.defaultReps, dto.defaultReps);
    });
  });

  group('ExerciseMapper', () {
    test('toDomain maps enums and lists', () {
      final exercise = mapper.toDomain(sampleDto());

      expect(exercise.id, 'bicep-curl-dumbbell');
      expect(exercise.primaryMuscles, [MuscleGroup.biceps]);
      expect(exercise.secondaryMuscles, [MuscleGroup.shoulders]);
      expect(exercise.equipment, Equipment.dumbbell);
      expect(exercise.difficulty, Difficulty.beginner);
      expect(exercise.instructions, hasLength(2));
    });

    test('toDomain falls back to safe defaults on unknown enum names', () {
      const dto = ExerciseDto(
        id: 'x',
        name: 'X',
        description: 'd',
        instructions: [],
        primaryMuscles: ['not-a-muscle'],
        secondaryMuscles: [],
        equipment: 'not-equipment',
        difficulty: 'not-a-difficulty',
        thumbnailAsset: 't.jpg',
        commonMistakes: [],
        tips: [],
        defaultSets: 3,
        defaultReps: 10,
        defaultRestSeconds: 60,
      );

      final exercise = mapper.toDomain(dto);

      expect(exercise.primaryMuscles, [MuscleGroup.fullBody]);
      expect(exercise.equipment, Equipment.bodyweight);
      expect(exercise.difficulty, Difficulty.beginner);
    });

    test('toDto writes enum .name strings', () {
      final dto = mapper.toDto(mapper.toDomain(sampleDto()));

      expect(dto.primaryMuscles, ['biceps']);
      expect(dto.equipment, 'dumbbell');
      expect(dto.difficulty, 'beginner');
    });

    test('enum labels are human-readable', () {
      expect(MuscleGroup.fullBody.label, 'Full Body');
      expect(MuscleGroup.chest.label, 'Chest');
      expect(Equipment.resistanceBand.label, 'Resistance Band');
      expect(Equipment.dumbbell.label, 'Dumbbell');
      expect(Difficulty.intermediate.label, 'Intermediate');
    });
  });
}
