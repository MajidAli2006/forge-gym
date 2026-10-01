import 'dart:async';
import 'dart:convert';

import 'package:forge_gym/features/challenges/domain/entities/challenge.dart';
import 'package:forge_gym/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enrollments as a JSON map in [SharedPreferences] (non-sensitive).
class PrefsChallengeEnrollmentRepository
    implements ChallengeEnrollmentRepository {
  PrefsChallengeEnrollmentRepository(this._prefs);

  final SharedPreferences _prefs;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  static const String storageKey = 'forge.challenge_enrollments';

  @override
  Stream<void> get changes => _changes.stream;

  Map<String, Map<String, dynamic>> _read() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <String, Map<String, dynamic>>{};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return <String, Map<String, dynamic>>{};
    }
  }

  Future<void> _write(Map<String, Map<String, dynamic>> data) async {
    await _prefs.setString(storageKey, jsonEncode(data));
    _changes.add(null);
  }

  @override
  Future<List<ChallengeEnrollment>> getAll() async {
    return _read().entries.map((entry) {
      final v = entry.value;
      return ChallengeEnrollment(
        challengeId: entry.key,
        joinedAt: DateTime.parse(v['joinedAt'] as String),
        completedAt: v['completedAt'] == null
            ? null
            : DateTime.parse(v['completedAt'] as String),
      );
    }).toList();
  }

  @override
  Future<void> join(String challengeId, {required DateTime at}) async {
    final data = _read();
    data[challengeId] = <String, dynamic>{'joinedAt': at.toIso8601String()};
    await _write(data);
  }

  @override
  Future<void> leave(String challengeId) async {
    final data = _read();
    if (data.remove(challengeId) != null) await _write(data);
  }

  @override
  Future<void> markCompleted(String challengeId, {required DateTime at}) async {
    final data = _read();
    final entry = data[challengeId];
    if (entry == null || entry['completedAt'] != null) return;
    entry['completedAt'] = at.toIso8601String();
    await _write(data);
  }
}
