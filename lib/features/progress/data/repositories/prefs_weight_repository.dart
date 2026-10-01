import 'dart:async';
import 'dart:convert';

import 'package:forge_gym/features/progress/domain/entities/weight_entry.dart';
import 'package:forge_gym/features/progress/domain/repositories/weight_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Body-weight history in [SharedPreferences] (non-sensitive data).
/// Entries are stored newest-first as a JSON list.
class PrefsWeightRepository implements WeightRepository {
  PrefsWeightRepository(this._prefs);

  final SharedPreferences _prefs;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  static const String _key = 'forge.body_weights';

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> logWeight(WeightEntry entry) async {
    final history = await getHistory();
    final updated = <WeightEntry>[entry, ...history]
      ..sort((a, b) => b.date.compareTo(a.date));
    final encoded = updated
        .map((e) => {'date': e.date.toIso8601String(), 'weightKg': e.weightKg})
        .toList();
    await _prefs.setString(_key, jsonEncode(encoded));
    _changes.add(null);
  }

  @override
  Future<List<WeightEntry>> getHistory() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <WeightEntry>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    final entries =
        decoded
            .map(
              (item) => WeightEntry(
                date: DateTime.parse(
                  (item as Map<String, dynamic>)['date'] as String,
                ),
                weightKg: (item['weightKg'] as num).toDouble(),
              ),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }
}
