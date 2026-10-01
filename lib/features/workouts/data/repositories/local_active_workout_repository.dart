import 'dart:convert';

import 'package:forge_gym/features/workouts/data/models/active_workout_dto.dart';
import 'package:forge_gym/features/workouts/domain/repositories/active_workout_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the in-progress session as JSON in SharedPreferences.
///
/// Non-sensitive training data (exercise ids, reps, weights) — the auth
/// token stays in secure storage. A restored session is normalized so the
/// app never resumes in the middle of a rest countdown.
class LocalActiveWorkoutRepository implements ActiveWorkoutRepository {
  LocalActiveWorkoutRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String storageKey = 'forge.active_session';

  @override
  Future<void> save(ActiveWorkout session) async {
    final dto = ActiveWorkoutDto.fromDomain(session);
    await _prefs.setString(storageKey, jsonEncode(dto.toJson()));
  }

  @override
  Future<ActiveWorkout?> load() async {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return null;
    try {
      final dto = ActiveWorkoutDto.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final session = dto.toDomain().normalizedForResume();
      if (!_hasValidPosition(session)) {
        // Stale snapshot (e.g. the plan changed) — drop it.
        await _prefs.remove(storageKey);
        return null;
      }
      return session;
    } catch (_) {
      // Corrupt snapshot — drop it rather than crash the session flow.
      await _prefs.remove(storageKey);
      return null;
    }
  }

  /// Guards against snapshots whose exercise/set indices no longer resolve,
  /// e.g. after the workout plan changed between app launches.
  bool _hasValidPosition(ActiveWorkout session) {
    if (session.exercises.isEmpty) return true;
    if (session.currentExerciseIndex < 0 ||
        session.currentExerciseIndex >= session.exercises.length) {
      return false;
    }
    final sets = session.currentExercise.sets;
    return session.currentSetIndex >= 0 &&
        session.currentSetIndex < sets.length;
  }

  @override
  Future<void> clear() => _prefs.remove(storageKey);
}
