import 'package:forge_gym/features/challenges/data/datasources/challenge_local_datasource.dart';
import 'package:forge_gym/features/challenges/domain/entities/challenge.dart';
import 'package:forge_gym/features/challenges/domain/repositories/challenge_repository.dart';

/// Catalogue from bundled JSON, ordered beginner → advanced.
class MockChallengeRepository implements ChallengeRepository {
  MockChallengeRepository(this._dataSource);

  final ChallengeLocalDataSource _dataSource;
  List<Challenge>? _cache;

  @override
  Future<List<Challenge>> getChallenges() async {
    final cached = _cache;
    if (cached != null) return cached;
    final dtos = await _dataSource.loadChallenges();
    final indexed =
        dtos.map((d) => d.toDomain()).toList().asMap().entries.toList()
          ..sort((a, b) {
            final byLevel = a.value.difficulty.index.compareTo(
              b.value.difficulty.index,
            );
            return byLevel != 0 ? byLevel : a.key.compareTo(b.key);
          });
    return _cache = List<Challenge>.unmodifiable(indexed.map((e) => e.value));
  }
}
