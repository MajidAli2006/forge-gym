import 'package:forge_gym/features/progress/domain/entities/weight_entry.dart';
import 'package:forge_gym/features/progress/domain/repositories/weight_repository.dart';

/// Loads body-weight history, newest first.
class GetWeightHistoryUseCase {
  const GetWeightHistoryUseCase(this._repository);

  final WeightRepository _repository;

  Future<List<WeightEntry>> call() => _repository.getHistory();
}
