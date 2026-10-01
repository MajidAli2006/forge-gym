import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';

enum WorkoutDetailStatus { initial, loading, loaded, error, deleted }

class WorkoutDetailState extends Equatable {
  const WorkoutDetailState({
    this.status = WorkoutDetailStatus.initial,
    this.workout,
    this.coverAsset,
    this.errorMessage,
  });

  final WorkoutDetailStatus status;
  final Workout? workout;

  /// Thumbnail of the first exercise, used as the header image.
  final String? coverAsset;
  final String? errorMessage;

  WorkoutDetailState copyWith({
    WorkoutDetailStatus? status,
    Workout? workout,
    String? coverAsset,
    String? errorMessage,
  }) {
    return WorkoutDetailState(
      status: status ?? this.status,
      workout: workout ?? this.workout,
      coverAsset: coverAsset ?? this.coverAsset,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    workout,
    coverAsset,
    errorMessage,
  ];
}
