import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/core/errors/failures.dart';
import 'package:forge_gym/features/auth/domain/repositories/auth_repository.dart';
import 'package:forge_gym/features/auth/domain/usecases/auth_usecases.dart';
import 'package:forge_gym/features/progress/domain/entities/weight_entry.dart';
import 'package:forge_gym/features/progress/domain/repositories/weight_repository.dart';
import 'package:forge_gym/features/progress/domain/usecases/get_progress_summary_usecase.dart';
import 'package:forge_gym/features/progress/domain/usecases/get_weight_history_usecase.dart';
import 'package:forge_gym/features/progress/domain/usecases/log_weight_usecase.dart';
import 'package:forge_gym/features/progress/presentation/cubit/progress_state.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';

/// Loads training statistics, workout history, and body-weight entries.
///
/// The screen only calls [load], [refresh] and [logWeight]. The cubit
/// refreshes itself whenever a workout finishes or a weight is logged
/// anywhere in the app, so the tab never shows stale numbers.
class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit({
    required GetProgressSummaryUseCase getProgressSummaryUseCase,
    required WorkoutHistoryRepository workoutHistoryRepository,
    required WeightRepository weightRepository,
    required GetWeightHistoryUseCase getWeightHistoryUseCase,
    required LogWeightUseCase logWeightUseCase,
    required AuthRepository authRepository,
    required UpdateProfileUseCase updateProfileUseCase,
  }) : _getProgressSummaryUseCase = getProgressSummaryUseCase,
       _workoutHistoryRepository = workoutHistoryRepository,
       _getWeightHistoryUseCase = getWeightHistoryUseCase,
       _logWeightUseCase = logWeightUseCase,
       _authRepository = authRepository,
       _updateProfileUseCase = updateProfileUseCase,
       super(const ProgressState()) {
    _subscriptions = <StreamSubscription<void>>[
      workoutHistoryRepository.changes.listen((_) => refresh()),
      weightRepository.changes.listen((_) => refresh()),
    ];
  }

  final GetProgressSummaryUseCase _getProgressSummaryUseCase;
  final WorkoutHistoryRepository _workoutHistoryRepository;
  final GetWeightHistoryUseCase _getWeightHistoryUseCase;
  final LogWeightUseCase _logWeightUseCase;
  final AuthRepository _authRepository;
  final UpdateProfileUseCase _updateProfileUseCase;

  late final List<StreamSubscription<void>> _subscriptions;

  Future<void> load() => _load(showLoading: true);

  /// Reloads in place without flashing the loading state.
  Future<void> refresh() => _load(showLoading: false);

  Future<void> _load({required bool showLoading}) async {
    if (showLoading) emit(state.copyWith(status: ProgressStatus.loading));
    try {
      final summary = await _getProgressSummaryUseCase();
      final history = await _workoutHistoryRepository.getHistory();
      final weights = await _getWeightHistoryUseCase();
      emit(
        state.copyWith(
          status: ProgressStatus.loaded,
          summary: summary,
          history: history,
          weeklyCounts: _weeklyCounts(history, DateTime.now()),
          weights: weights,
        ),
      );
    } catch (_) {
      if (!showLoading && state.status == ProgressStatus.loaded) return;
      emit(
        state.copyWith(
          status: ProgressStatus.error,
          errorMessage:
              'Could not load your progress. Check your connection and try again.',
        ),
      );
    }
  }

  /// Records today's body-weight measurement and mirrors it onto the
  /// member's profile so the two screens never disagree.
  Future<void> logWeight(double weightKg) async {
    emit(state.copyWith(status: ProgressStatus.savingWeight));
    try {
      await _logWeightUseCase(
        WeightEntry(date: DateTime.now(), weightKg: weightKg),
      );
      final weights = await _getWeightHistoryUseCase();
      emit(state.copyWith(status: ProgressStatus.loaded, weights: weights));
      final user = await _authRepository.currentUser();
      if (user != null && user.weightKg != weightKg) {
        await _updateProfileUseCase(user.copyWith(weightKg: weightKg));
      }
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: ProgressStatus.loaded,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProgressStatus.loaded,
          errorMessage: 'Could not save your weight. Please try again.',
        ),
      );
    }
  }

  /// Finished-workout counts for Mon..Sun of the week containing [now].
  static List<int> _weeklyCounts(List<CompletedWorkout> history, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final counts = List<int>.filled(7, 0);
    for (final workout in history) {
      final day = DateTime(
        workout.finishedAt.year,
        workout.finishedAt.month,
        workout.finishedAt.day,
      );
      final offset = day.difference(weekStart).inDays;
      if (offset >= 0 && offset < 7) counts[offset]++;
    }
    return counts;
  }

  @override
  Future<void> close() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    return super.close();
  }
}
