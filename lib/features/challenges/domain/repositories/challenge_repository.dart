import 'package:forge_gym/features/challenges/domain/entities/challenge.dart';

/// Catalogue of challenges the gym offers. Bundled JSON today, API later.
abstract class ChallengeRepository {
  Future<List<Challenge>> getChallenges();
}

/// The member's joined / completed challenges. Local today, synced later.
abstract class ChallengeEnrollmentRepository {
  Future<List<ChallengeEnrollment>> getAll();
  Future<void> join(String challengeId, {required DateTime at});
  Future<void> leave(String challengeId);
  Future<void> markCompleted(String challengeId, {required DateTime at});

  /// Emits after every write.
  Stream<void> get changes;
}
