import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:forge_gym/features/workouts/domain/usecases/delete_custom_workout_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_workout_by_id_usecase.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workout_detail_state.dart';

/// Loads a single workout plan for the detail screen.
class WorkoutDetailCubit extends Cubit<WorkoutDetailState> {
  WorkoutDetailCubit(
    this._getWorkoutById, {
    ExerciseRepository? exercises,
    DeleteCustomWorkoutUseCase? deleteCustomWorkout,
  }) : _exercises = exercises,
       _delete = deleteCustomWorkout,
       super(const WorkoutDetailState());

  final GetWorkoutByIdUseCase _getWorkoutById;
  final ExerciseRepository? _exercises;
  final DeleteCustomWorkoutUseCase? _delete;

  /// Only personal routines can be removed.
  bool get canDelete => _delete != null && (state.workout?.isCustom ?? false);

  Future<void> deleteRoutine() async {
    final workout = state.workout;
    final delete = _delete;
    if (workout == null || delete == null || !workout.isCustom) return;
    try {
      await delete(workout.id);
      emit(state.copyWith(status: WorkoutDetailStatus.deleted));
    } catch (_) {
      emit(
        state.copyWith(errorMessage: 'Could not delete the routine.'),
      );
    }
  }

  Future<void> loadById(String id) async {
    emit(
      state.copyWith(status: WorkoutDetailStatus.loading, errorMessage: null),
    );
    try {
      final workout = await _getWorkoutById(id);
      if (workout == null) {
        emit(
          state.copyWith(
            status: WorkoutDetailStatus.error,
            errorMessage: 'Workout not found.',
          ),
        );
        return;
      }
      String? cover;
      if (workout.exercises.isNotEmpty) {
        cover = (await _exercises?.getExerciseById(
          workout.exercises.first.exerciseId,
        ))?.thumbnailAsset;
      }
      emit(
        state.copyWith(
          status: WorkoutDetailStatus.loaded,
          workout: workout,
          coverAsset: cover,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: WorkoutDetailStatus.error,
          errorMessage:
              'Could not load this workout. Check your connection and try again.',
        ),
      );
    }
  }
}
