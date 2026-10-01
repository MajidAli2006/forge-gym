import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:forge_gym/features/exercises/data/models/exercise_dto.dart';

/// Reads exercise rows. Abstract so tests can substitute a fake;
/// the real implementation loads the bundled mock JSON once and caches it.
abstract class ExerciseLocalDataSource {
  Future<List<ExerciseDto>> loadExercises();
}

class AssetExerciseLocalDataSource implements ExerciseLocalDataSource {
  AssetExerciseLocalDataSource({this.assetPath = 'assets/mock/exercises.json'});

  final String assetPath;
  List<ExerciseDto>? _cache;

  @override
  Future<List<ExerciseDto>> loadExercises() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    final dtos = decoded
        .map((e) => ExerciseDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _cache = dtos;
    return dtos;
  }
}
