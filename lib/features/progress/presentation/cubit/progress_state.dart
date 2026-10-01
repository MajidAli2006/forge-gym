import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/progress/domain/entities/progress_summary.dart';
import 'package:forge_gym/features/progress/domain/entities/weight_entry.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';

/// Lifecycle of the progress screen data load.
enum ProgressStatus { initial, loading, loaded, savingWeight, error }

/// Everything the progress screen renders.
class ProgressState extends Equatable {
  const ProgressState({
    this.status = ProgressStatus.initial,
    this.summary,
    this.history = const <CompletedWorkout>[],
    this.weeklyCounts = const <int>[0, 0, 0, 0, 0, 0, 0],
    this.weights = const <WeightEntry>[],
    this.errorMessage,
  });

  final ProgressStatus status;
  final ProgressSummary? summary;
  final List<CompletedWorkout> history;

  /// Finished-workout counts for Mon..Sun of the current week.
  final List<int> weeklyCounts;
  final List<WeightEntry> weights;
  final String? errorMessage;

  WeightEntry? get latestWeight => weights.isNotEmpty ? weights.first : null;

  ProgressState copyWith({
    ProgressStatus? status,
    ProgressSummary? summary,
    List<CompletedWorkout>? history,
    List<int>? weeklyCounts,
    List<WeightEntry>? weights,
    String? errorMessage,
  }) {
    return ProgressState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      history: history ?? this.history,
      weeklyCounts: weeklyCounts ?? this.weeklyCounts,
      weights: weights ?? this.weights,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    summary,
    history,
    weeklyCounts,
    weights,
    errorMessage,
  ];
}
