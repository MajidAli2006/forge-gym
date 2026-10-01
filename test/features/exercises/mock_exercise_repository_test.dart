import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/exercises/data/datasources/exercise_local_datasource.dart';
import 'package:forge_gym/features/exercises/data/models/exercise_dto.dart';
import 'package:forge_gym/features/exercises/data/repositories/mock_exercise_repository.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

ExerciseDto _dto({
  required String id,
  required String name,
  String description = 'desc',
  List<String> primary = const ['chest'],
  List<String> secondary = const [],
  String equipment = 'dumbbell',
  String difficulty = 'beginner',
}) {
  return ExerciseDto(
    id: id,
    name: name,
    description: description,
    instructions: const ['Do it'],
    primaryMuscles: primary,
    secondaryMuscles: secondary,
    equipment: equipment,
    difficulty: difficulty,
    thumbnailAsset: 'assets/exercises/$id/thumb.jpg',
    commonMistakes: const [],
    tips: const [],
    defaultSets: 3,
    defaultReps: 10,
    defaultRestSeconds: 60,
  );
}

class _FakeDataSource implements ExerciseLocalDataSource {
  @override
  Future<List<ExerciseDto>> loadExercises() async => [
    _dto(id: 'a', name: 'Dumbbell Bicep Curl', primary: const ['biceps']),
    _dto(
      id: 'b',
      name: 'Barbell Bench Press',
      primary: const ['chest'],
      equipment: 'barbell',
      difficulty: 'intermediate',
    ),
    _dto(
      id: 'c',
      name: 'Push Up',
      description: 'Bodyweight chest press',
      primary: const ['chest'],
      secondary: const ['triceps'],
      equipment: 'bodyweight',
      difficulty: 'beginner',
    ),
  ];
}

void main() {
  group('MockExerciseRepository', () {
    late MockExerciseRepository repository;

    setUp(() {
      repository = MockExerciseRepository(_FakeDataSource());
    });

    test('returns all exercises without filters', () async {
      final exercises = await repository.getExercises();
      expect(exercises, hasLength(3));
    });

    test('query matches name case-insensitively', () async {
      final exercises = await repository.getExercises(query: 'BENCH');
      expect(exercises.map((e) => e.id), ['b']);
    });

    test('query matches description and muscle labels', () async {
      final byDescription = await repository.getExercises(query: 'bodyweight');
      expect(byDescription.map((e) => e.id), contains('c'));

      final byMuscle = await repository.getExercises(query: 'triceps');
      expect(byMuscle.map((e) => e.id), ['c']);
    });

    test('filters by muscle including secondary muscles', () async {
      final exercises = await repository.getExercises(
        muscle: MuscleGroup.triceps,
      );
      expect(exercises.map((e) => e.id), ['c']);
    });

    test('filters by equipment and difficulty', () async {
      final byEquipment = await repository.getExercises(
        equipment: Equipment.barbell,
      );
      expect(byEquipment.map((e) => e.id), ['b']);

      final byDifficulty = await repository.getExercises(
        difficulty: Difficulty.intermediate,
      );
      expect(byDifficulty.map((e) => e.id), ['b']);
    });

    test('combines query and filters', () async {
      final exercises = await repository.getExercises(
        query: 'press',
        muscle: MuscleGroup.chest,
        equipment: Equipment.barbell,
      );
      expect(exercises.map((e) => e.id), ['b']);
    });

    test('getExerciseById returns the exercise or null', () async {
      expect(
        (await repository.getExerciseById('a'))?.name,
        'Dumbbell Bicep Curl',
      );
      expect(await repository.getExerciseById('missing'), isNull);
    });
  });
}
