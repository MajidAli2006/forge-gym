import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/workouts/domain/entities/active_workout.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';

enum WorkoutSessionStatus { initial, loading, active, finished }

/// State of the live workout session.
///
/// `restSecondsLeft > 0` means the rest overlay is showing; the entity's
/// own [ActiveWorkoutStatus] mirrors this for the persisted snapshot.
class WorkoutSessionState extends Equatable {
  const WorkoutSessionState({
    this.status = WorkoutSessionStatus.initial,
    this.session,
    this.restSecondsLeft = 0,
    this.lastCompleted,
    this.errorMessage,
  });

  final WorkoutSessionStatus status;
  final ActiveWorkout? session;

  /// Countdown shown in the rest overlay. Zero = not resting.
  final int restSecondsLeft;
  final CompletedWorkout? lastCompleted;
  final String? errorMessage;

  bool get isResting => restSecondsLeft > 0;

  ActiveExercise? get currentExercise => session?.currentExercise;

  int get totalExercises => session?.exercises.length ?? 0;

  WorkoutSessionState copyWith({
    WorkoutSessionStatus? status,
    ActiveWorkout? session,
    int? restSecondsLeft,
    CompletedWorkout? lastCompleted,
    String? errorMessage,
  }) {
    return WorkoutSessionState(
      status: status ?? this.status,
      session: session ?? this.session,
      restSecondsLeft: restSecondsLeft ?? this.restSecondsLeft,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    session,
    restSecondsLeft,
    lastCompleted,
    errorMessage,
  ];
}
