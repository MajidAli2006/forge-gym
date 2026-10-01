import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/usecases/get_exercises_usecase.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercises_state.dart';

/// Owns the exercise library list: loading, searching, and filtering.
/// Every filter change re-queries through the use case so the UI stays a
/// pure function of [ExercisesState].
class ExercisesCubit extends Cubit<ExercisesState> {
  ExercisesCubit(this._getExercises) : super(const ExercisesState());

  final GetExercisesUseCase _getExercises;

  Future<void> load() async {
    emit(state.copyWith(status: ExercisesStatus.loading));
    try {
      final exercises = await _getExercises.call(
        query: state.query,
        muscle: state.muscle,
        equipment: state.equipment,
        difficulty: state.difficulty,
      );
      emit(
        state.copyWith(status: ExercisesStatus.loaded, exercises: exercises),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ExercisesStatus.error,
          errorMessage: 'Could not load exercises. Please try again.',
        ),
      );
    }
  }

  Future<void> setQuery(String query) async {
    if (query == state.query) return;
    emit(state.copyWith(query: query));
    await _reloadQuietly();
  }

  Future<void> setMuscle(MuscleGroup? muscle) async {
    emit(state.copyWith(muscle: muscle, clearMuscle: muscle == null));
    await _reloadQuietly();
  }

  Future<void> setEquipment(Equipment? equipment) async {
    emit(
      state.copyWith(equipment: equipment, clearEquipment: equipment == null),
    );
    await _reloadQuietly();
  }

  Future<void> setDifficulty(Difficulty? difficulty) async {
    emit(
      state.copyWith(
        difficulty: difficulty,
        clearDifficulty: difficulty == null,
      ),
    );
    await _reloadQuietly();
  }

  Future<void> clearFilters() async {
    emit(
      state.copyWith(
        query: '',
        clearMuscle: true,
        clearEquipment: true,
        clearDifficulty: true,
      ),
    );
    await _reloadQuietly();
  }

  /// Re-query without flashing the full loading state — filters feel instant.
  Future<void> _reloadQuietly() async {
    try {
      final exercises = await _getExercises.call(
        query: state.query,
        muscle: state.muscle,
        equipment: state.equipment,
        difficulty: state.difficulty,
      );
      emit(
        state.copyWith(status: ExercisesStatus.loaded, exercises: exercises),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ExercisesStatus.error,
          errorMessage: 'Could not load exercises. Please try again.',
        ),
      );
    }
  }
}
