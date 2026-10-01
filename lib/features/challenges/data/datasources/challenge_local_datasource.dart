import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:forge_gym/features/challenges/data/models/challenge_dto.dart';

/// Loads the challenge catalogue. Abstract so tests can supply a fake.
abstract class ChallengeLocalDataSource {
  Future<List<ChallengeDto>> loadChallenges();
}

class AssetChallengeDataSource implements ChallengeLocalDataSource {
  const AssetChallengeDataSource();

  @override
  Future<List<ChallengeDto>> loadChallenges() async {
    final raw = await rootBundle.loadString('assets/mock/challenges.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => ChallengeDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
