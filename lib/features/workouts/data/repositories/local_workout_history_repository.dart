import 'dart:async';
import 'dart:convert';

import 'package:forge_gym/features/workouts/data/models/completed_workout_dto.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Finished-workout history as a JSON list in SharedPreferences,
/// newest first. Non-sensitive training data.
class LocalWorkoutHistoryRepository implements WorkoutHistoryRepository {
  LocalWorkoutHistoryRepository(this._prefs);

  final SharedPreferences _prefs;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  static const String storageKey = 'forge.workout_history';

  @override
  Stream<void> get changes => _changes.stream;

  /// Hard cap so the stored list cannot grow without bound.
  static const int maxStored = 200;

  @override
  Future<void> saveCompleted(CompletedWorkout workout) async {
    final history = await getHistory(limit: maxStored);
    final updated = <CompletedWorkout>[
      workout,
      ...history,
    ].take(maxStored).toList();
    final json = updated
        .map((e) => CompletedWorkoutDto.fromDomain(e).toJson())
        .toList();
    await _prefs.setString(storageKey, jsonEncode(json));
    _changes.add(null);
  }

  @override
  Future<void> upsertCompleted(CompletedWorkout workout) async {
    final history = await getHistory(limit: maxStored);
    final index = history.indexWhere((w) => w.id == workout.id);
    final updated = index == -1
        ? <CompletedWorkout>[workout, ...history]
        : (List<CompletedWorkout>.of(history)..[index] = workout);
    final json = updated
        .take(maxStored)
        .map((e) => CompletedWorkoutDto.fromDomain(e).toJson())
        .toList();
    await _prefs.setString(storageKey, jsonEncode(json));
    _changes.add(null);
  }

  @override
  Future<List<CompletedWorkout>> getHistory({int limit = 50}) async {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return <CompletedWorkout>[];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list
          .take(limit)
          .map(CompletedWorkoutDto.fromJson)
          .map((d) => d.toDomain())
          .toList();
    } catch (_) {
      return <CompletedWorkout>[];
    }
  }
}
