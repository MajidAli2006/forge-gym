import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/progress/data/repositories/prefs_weight_repository.dart';
import 'package:forge_gym/features/progress/domain/entities/weight_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('round-trips weight entries newest-first', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = PrefsWeightRepository(prefs);

    expect(await repository.getHistory(), isEmpty);

    await repository.logWeight(
      WeightEntry(date: DateTime(2026, 9, 28), weightKg: 82.5),
    );
    await repository.logWeight(
      WeightEntry(date: DateTime(2026, 9, 30), weightKg: 82.0),
    );

    final history = await repository.getHistory();
    expect(history, hasLength(2));
    expect(history.first.weightKg, 82.0);
    expect(history.first.date, DateTime(2026, 9, 30));
    expect(history.last.weightKg, 82.5);
  });

  test('persists across repository instances', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await PrefsWeightRepository(
      prefs,
    ).logWeight(WeightEntry(date: DateTime(2026, 9, 30), weightKg: 80));

    final reread = await PrefsWeightRepository(prefs).getHistory();
    expect(reread, hasLength(1));
    expect(reread.first.weightKg, 80);
  });
}
