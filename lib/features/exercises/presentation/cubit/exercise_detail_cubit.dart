import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/core/errors/failures.dart';
import 'package:forge_gym/core/utils/formatters.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/usecases/get_exercise_by_id_usecase.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercise_detail_state.dart';
import 'package:forge_gym/features/workouts/domain/usecases/quick_log_set_usecase.dart';

/// Loads a single exercise for the detail screen and records quick sets
/// against it (through the workouts feature's domain use case, never its
/// data layer).
class ExerciseDetailCubit extends Cubit<ExerciseDetailState> {
  ExerciseDetailCubit(this._getExerciseById, {QuickLogSetUseCase? quickLogSet})
    : _quickLogSet = quickLogSet,
      super(const ExerciseDetailState());

  final GetExerciseByIdUseCase _getExerciseById;
  final QuickLogSetUseCase? _quickLogSet;

  /// Whether this screen can record sets (false when the workouts feature
  /// is not wired, e.g. in isolated widget tests).
  bool get canLogSets => _quickLogSet != null;

  Future<void> loadById(String id) async {
    emit(const ExerciseDetailState(status: ExerciseDetailStatus.loading));
    try {
      final exercise = await _getExerciseById.call(id);
      if (exercise == null) {
        emit(const ExerciseDetailState(status: ExerciseDetailStatus.notFound));
      } else {
        emit(
          ExerciseDetailState(
            status: ExerciseDetailStatus.loaded,
            exercise: exercise,
          ),
        );
      }
    } catch (_) {
      emit(const ExerciseDetailState(status: ExerciseDetailStatus.error));
    }
  }

  /// Saves one set ([count] reps, or seconds for timed holds) to today's
  /// quick-log history entry.
  Future<void> logSet({required int count, double weightKg = 0}) async {
    final exercise = state.exercise;
    final useCase = _quickLogSet;
    if (exercise == null || useCase == null || state.isLogging) return;
    emit(state.copyWith(isLogging: true));
    try {
      await useCase(exercise: exercise, count: count, weightKg: weightKg);
      final timed = exercise.tracking.isTimed;
      final what = timed
          ? '${count}s ${exercise.name}'
          : '$count × ${exercise.name}'
                '${weightKg > 0 ? ' at ${Formatters.kg(weightKg)}' : ''}';
      emit(
        state.copyWith(
          isLogging: false,
          logMessage: 'Saved: $what. Counted in your progress.',
        ),
      );
    } on Failure catch (failure) {
      emit(state.copyWith(isLogging: false, logError: failure.message));
    } catch (_) {
      emit(
        state.copyWith(
          isLogging: false,
          logError: 'Could not save the set. Please try again.',
        ),
      );
    }
  }
}
