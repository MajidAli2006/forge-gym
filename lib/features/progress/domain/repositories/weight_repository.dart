import 'package:forge_gym/features/progress/domain/entities/weight_entry.dart';

/// Contract for body-weight tracking. Local prefs today, cloud sync later.
abstract class WeightRepository {
  Future<void> logWeight(WeightEntry entry);
  Future<List<WeightEntry>> getHistory();

  /// Emits after every successful write.
  Stream<void> get changes;
}
