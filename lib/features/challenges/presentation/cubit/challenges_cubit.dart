import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:forge_gym/features/challenges/domain/usecases/get_challenge_progress_usecase.dart';
import 'package:forge_gym/features/challenges/presentation/cubit/challenges_state.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';

/// Lists challenges with live progress; joins and leaves them.
///
/// Refreshes itself when a workout finishes or an enrollment changes, so
/// progress bars move without the member touching anything.
class ChallengesCubit extends Cubit<ChallengesState> {
  ChallengesCubit({
    required GetChallengeProgressUseCase getProgress,
    required ChallengeEnrollmentRepository enrollments,
    required WorkoutHistoryRepository history,
  }) : _getProgress = getProgress,
       _enrollments = enrollments,
       super(const ChallengesState()) {
    _subscriptions = <StreamSubscription<void>>[
      history.changes.listen((_) => refresh()),
      enrollments.changes.listen((_) => refresh()),
    ];
  }

  final GetChallengeProgressUseCase _getProgress;
  final ChallengeEnrollmentRepository _enrollments;
  late final List<StreamSubscription<void>> _subscriptions;

  Future<void> load() => _load(showLoading: true);
  Future<void> refresh() => _load(showLoading: false);

  Future<void> _load({required bool showLoading}) async {
    if (showLoading) emit(state.copyWith(status: ChallengesStatus.loading));
    try {
      final items = await _getProgress();
      emit(state.copyWith(status: ChallengesStatus.loaded, items: items));
    } catch (_) {
      if (!showLoading && state.status == ChallengesStatus.loaded) return;
      emit(
        state.copyWith(
          status: ChallengesStatus.error,
          errorMessage: 'Could not load challenges. Please try again.',
        ),
      );
    }
  }

  Future<void> join(String challengeId) =>
      _enrollments.join(challengeId, at: DateTime.now());

  Future<void> leave(String challengeId) => _enrollments.leave(challengeId);

  @override
  Future<void> close() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    return super.close();
  }
}
