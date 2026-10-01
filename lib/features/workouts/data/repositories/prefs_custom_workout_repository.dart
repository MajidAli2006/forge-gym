import 'dart:async';
import 'dart:convert';

import 'package:forge_gym/features/workouts/data/models/workout_dto.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/custom_workout_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Member-built routines as a JSON list in [SharedPreferences].
class PrefsCustomWorkoutRepository implements CustomWorkoutRepository {
  PrefsCustomWorkoutRepository(this._prefs);

  final SharedPreferences _prefs;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  static const String storageKey = 'forge.custom_workouts';

  @override
  Stream<void> get changes => _changes.stream;

  List<Workout> _read() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <Workout>[];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list
          .map(WorkoutDto.fromJson)
          .map((d) => d.toDomain().copyWith(isCustom: true))
          .toList();
    } catch (_) {
      return <Workout>[];
    }
  }

  Future<void> _write(List<Workout> workouts) async {
    final json = workouts
        .map((w) => WorkoutDto.fromDomain(w).toJson())
        .toList();
    await _prefs.setString(storageKey, jsonEncode(json));
    _changes.add(null);
  }

  @override
  Future<List<Workout>> getAll() async => _read();

  @override
  Future<Workout?> getById(String id) async {
    for (final workout in _read()) {
      if (workout.id == id) return workout;
    }
    return null;
  }

  @override
  Future<void> save(Workout workout) async {
    final all = _read();
    final index = all.indexWhere((w) => w.id == workout.id);
    if (index == -1) {
      all.insert(0, workout);
    } else {
      all[index] = workout;
    }
    await _write(all);
  }

  @override
  Future<void> delete(String id) async {
    final all = _read();
    final before = all.length;
    all.removeWhere((w) => w.id == id);
    if (all.length != before) await _write(all);
  }
}
