import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/exercises/data/mappers/exercise_mapper.dart';
import 'package:forge_gym/features/exercises/data/models/exercise_dto.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

/// Guards the bundled mock library: every row must parse through the real
/// DTO + mapper path and satisfy the content contract (steps, mistakes,
/// tips, valid enum names, asset paths matching the media pipeline layout).
void main() {
  const mapper = ExerciseMapper();

  List<Map<String, dynamic>> loadRows() {
    final file = File('assets/mock/exercises.json');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'assets/mock/exercises.json must exist',
    );
    final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    return decoded.map((e) => e as Map<String, dynamic>).toList();
  }

  group('exercises.json content contract', () {
    test('contains 52 exercises with unique ids', () {
      final rows = loadRows();
      expect(rows, hasLength(52));
      final ids = rows.map((r) => r['id'] as String).toList();
      expect(ids.toSet(), hasLength(52));
    });

    test('every row parses to a valid domain Exercise', () {
      final validMuscles = MuscleGroup.values.map((m) => m.name).toSet();
      final validEquipment = Equipment.values.map((e) => e.name).toSet();
      final validDifficulty = Difficulty.values.map((d) => d.name).toSet();

      for (final row in loadRows()) {
        final dto = ExerciseDto.fromJson(row);
        final exercise = mapper.toDomain(dto);

        expect(exercise.id, isNotEmpty);
        expect(exercise.name, isNotEmpty);
        expect(exercise.description, isNotEmpty);
        expect(
          exercise.instructions.length,
          inInclusiveRange(4, 8),
          reason: '${exercise.id} instructions',
        );
        expect(
          exercise.commonMistakes.length,
          inInclusiveRange(3, 4),
          reason: '${exercise.id} mistakes',
        );
        expect(
          exercise.tips.length,
          inInclusiveRange(2, 3),
          reason: '${exercise.id} tips',
        );
        expect(exercise.primaryMuscles, isNotEmpty);
        for (final m in [
          ...exercise.primaryMuscles,
          ...exercise.secondaryMuscles,
        ]) {
          expect(validMuscles, contains(m.name));
        }
        expect(validEquipment, contains(exercise.equipment.name));
        expect(validDifficulty, contains(exercise.difficulty.name));
        expect(
          exercise.thumbnailAsset,
          'assets/exercises/${exercise.id}/thumb.jpg',
        );
        expect(exercise.videoAsset, 'exercises/${exercise.id}/demo.mp4');
        expect(exercise.defaultSets, greaterThan(0));
        expect(exercise.defaultReps, greaterThan(0));
        expect(exercise.defaultRestSeconds, greaterThan(0));
      }
    });

    test('new chest entries resolve correctly', () {
      final rows = loadRows();
      final byId = {for (final r in rows) r['id'] as String: r};

      final fly = mapper.toDomain(
        ExerciseDto.fromJson(byId['chest-fly-dumbbell']!),
      );
      expect(fly.name, 'Dumbbell Chest Fly');
      expect(fly.primaryMuscles, [MuscleGroup.chest]);
      expect(fly.equipment, Equipment.dumbbell);

      final crossover = mapper.toDomain(
        ExerciseDto.fromJson(byId['cable-crossover']!),
      );
      expect(crossover.equipment, Equipment.cable);

      final pecDeck = mapper.toDomain(
        ExerciseDto.fromJson(byId['pec-deck-machine']!),
      );
      expect(pecDeck.difficulty, Difficulty.beginner);
      expect(pecDeck.equipment, Equipment.machine);
    });

    test('new back/shoulder entries resolve correctly', () {
      final rows = loadRows();
      final byId = {for (final r in rows) r['id'] as String: r};

      final row = mapper.toDomain(
        ExerciseDto.fromJson(byId['bent-over-row-barbell']!),
      );
      expect(row.primaryMuscles, [MuscleGroup.back]);
      expect(row.secondaryMuscles, contains(MuscleGroup.biceps));

      final arnold = mapper.toDomain(
        ExerciseDto.fromJson(byId['arnold-press-dumbbell']!),
      );
      expect(arnold.primaryMuscles, [MuscleGroup.shoulders]);
      expect(arnold.difficulty, Difficulty.intermediate);

      final facePull = mapper.toDomain(
        ExerciseDto.fromJson(byId['face-pull-cable']!),
      );
      expect(facePull.primaryMuscles, [MuscleGroup.shoulders]);
    });

    test('new arm/leg/core entries resolve correctly', () {
      final rows = loadRows();
      final byId = {for (final r in rows) r['id'] as String: r};

      final hammer = mapper.toDomain(
        ExerciseDto.fromJson(byId['hammer-curl-dumbbell']!),
      );
      expect(hammer.primaryMuscles, [MuscleGroup.biceps]);

      final skull = mapper.toDomain(
        ExerciseDto.fromJson(byId['skullcrusher-ezbar']!),
      );
      expect(skull.primaryMuscles, [MuscleGroup.triceps]);
      expect(skull.equipment, Equipment.barbell); // EZ-bar maps to barbell

      final hipThrust = mapper.toDomain(
        ExerciseDto.fromJson(byId['hip-thrust-barbell']!),
      );
      expect(hipThrust.primaryMuscles, [MuscleGroup.glutes]);

      final sumo = mapper.toDomain(
        ExerciseDto.fromJson(byId['sumo-deadlift-barbell']!),
      );
      expect(sumo.difficulty, Difficulty.advanced);

      final deadBug = mapper.toDomain(ExerciseDto.fromJson(byId['dead-bug']!));
      expect(deadBug.primaryMuscles, [MuscleGroup.core]);
      expect(deadBug.equipment, Equipment.bodyweight);

      final sidePlank = mapper.toDomain(
        ExerciseDto.fromJson(byId['side-plank']!),
      );
      expect(sidePlank.tracking, TrackingType.timed);
      expect(sidePlank.defaultReps, 20); // seconds held
    });
  });
}
