import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/challenges/domain/entities/challenge.dart';

enum ChallengesStatus { initial, loading, loaded, error }

class ChallengesState extends Equatable {
  const ChallengesState({
    this.status = ChallengesStatus.initial,
    this.items = const <ChallengeProgress>[],
    this.errorMessage,
  });

  final ChallengesStatus status;
  final List<ChallengeProgress> items;
  final String? errorMessage;

  List<ChallengeProgress> get active =>
      items.where((p) => p.status == ChallengeStatus.active).toList();
  List<ChallengeProgress> get available => items
      .where(
        (p) =>
            p.status == ChallengeStatus.available ||
            p.status == ChallengeStatus.expired,
      )
      .toList();
  List<ChallengeProgress> get completed =>
      items.where((p) => p.status == ChallengeStatus.completed).toList();

  ChallengesState copyWith({
    ChallengesStatus? status,
    List<ChallengeProgress>? items,
    String? errorMessage,
  }) {
    return ChallengesState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
