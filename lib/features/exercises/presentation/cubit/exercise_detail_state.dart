import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

enum ExerciseDetailStatus { initial, loading, loaded, notFound, error }

class ExerciseDetailState extends Equatable {
  const ExerciseDetailState({
    this.status = ExerciseDetailStatus.initial,
    this.exercise,
    this.isLogging = false,
    this.logMessage,
    this.logError,
  });

  final ExerciseDetailStatus status;
  final Exercise? exercise;

  /// A quick set is being written to history.
  final bool isLogging;

  /// One-shot confirmation after a set was saved (the screen shows it and
  /// the cubit clears it).
  final String? logMessage;

  /// One-shot failure message for a set that could not be saved.
  final String? logError;

  ExerciseDetailState copyWith({
    ExerciseDetailStatus? status,
    Exercise? exercise,
    bool? isLogging,
    String? logMessage,
    String? logError,
  }) {
    return ExerciseDetailState(
      status: status ?? this.status,
      exercise: exercise ?? this.exercise,
      isLogging: isLogging ?? this.isLogging,
      logMessage: logMessage,
      logError: logError,
    );
  }

  @override
  List<Object?> get props => [
    status,
    exercise,
    isLogging,
    logMessage,
    logError,
  ];
}
