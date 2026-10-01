import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:forge_gym/core/errors/failures.dart';
import 'package:forge_gym/features/workouts/data/models/workout_dto.dart';

/// Loads workout plans from the bundled mock JSON. The future API data
/// source will implement this same interface.
abstract class WorkoutLocalDataSource {
  Future<List<WorkoutDto>> loadWorkouts();
}

class AssetWorkoutLocalDataSource implements WorkoutLocalDataSource {
  static const String assetPath = 'assets/mock/workouts.json';

  @override
  Future<List<WorkoutDto>> loadWorkouts() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => WorkoutDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const CacheFailure(
        'Workout plans are unavailable right now. Please try again.',
      );
    }
  }
}
