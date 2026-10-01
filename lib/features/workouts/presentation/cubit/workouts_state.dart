import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';

enum WorkoutsStatus { initial, loading, loaded, error }

class WorkoutsState extends Equatable {
  const WorkoutsState({
    this.status = WorkoutsStatus.initial,
    this.workouts = const <Workout>[],
    this.covers = const <String, String>{},
    this.errorMessage,
  });

  final WorkoutsStatus status;
  final List<Workout> workouts;

  /// Workout id → thumbnail asset of its first exercise (card artwork).
  final Map<String, String> covers;
  final String? errorMessage;

  /// Routines the member built (shown first, editable).
  List<Workout> get routines =>
      workouts.where((w) => w.isCustom).toList(growable: false);

  /// The gym's bundled plans.
  List<Workout> get plans =>
      workouts.where((w) => !w.isCustom).toList(growable: false);

  WorkoutsState copyWith({
    WorkoutsStatus? status,
    List<Workout>? workouts,
    Map<String, String>? covers,
    String? errorMessage,
  }) {
    return WorkoutsState(
      status: status ?? this.status,
      workouts: workouts ?? this.workouts,
      covers: covers ?? this.covers,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, workouts, covers, errorMessage];
}
