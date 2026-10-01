import 'package:forge_gym/core/errors/failures.dart';
import 'package:forge_gym/features/progress/domain/entities/weight_entry.dart';
import 'package:forge_gym/features/progress/domain/repositories/weight_repository.dart';

/// Records a body-weight measurement after basic sanity validation.
class LogWeightUseCase {
  const LogWeightUseCase(this._repository);

  final WeightRepository _repository;

  Future<void> call(WeightEntry entry) {
    if (entry.weightKg <= 0 || entry.weightKg > 500) {
      throw const ValidationFailure('Enter a realistic weight in kilograms.');
    }
    return _repository.logWeight(entry);
  }
}
