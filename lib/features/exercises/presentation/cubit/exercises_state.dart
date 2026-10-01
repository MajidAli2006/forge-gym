import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

enum ExercisesStatus { initial, loading, loaded, error }

/// Immutable UI state for the exercise library screen, including the
/// active search + filter selection.
class ExercisesState extends Equatable {
  const ExercisesState({
    this.status = ExercisesStatus.initial,
    this.exercises = const <Exercise>[],
    this.query = '',
    this.muscle,
    this.equipment,
    this.difficulty,
    this.errorMessage,
  });

  final ExercisesStatus status;
  final List<Exercise> exercises;
  final String query;
  final MuscleGroup? muscle;
  final Equipment? equipment;
  final Difficulty? difficulty;
  final String? errorMessage;

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      muscle != null ||
      equipment != null ||
      difficulty != null;

  ExercisesState copyWith({
    ExercisesStatus? status,
    List<Exercise>? exercises,
    String? query,
    MuscleGroup? muscle,
    bool clearMuscle = false,
    Equipment? equipment,
    bool clearEquipment = false,
    Difficulty? difficulty,
    bool clearDifficulty = false,
    String? errorMessage,
  }) {
    return ExercisesState(
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      query: query ?? this.query,
      muscle: clearMuscle ? null : (muscle ?? this.muscle),
      equipment: clearEquipment ? null : (equipment ?? this.equipment),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    exercises,
    query,
    muscle,
    equipment,
    difficulty,
    errorMessage,
  ];
}
