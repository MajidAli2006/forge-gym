import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_workouts_usecase.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workouts_state.dart';

/// Loads the workout catalogue (the member's routines + the gym's plans)
/// and reloads whenever a routine is saved or deleted.
class WorkoutsCubit extends Cubit<WorkoutsState> {
  WorkoutsCubit(
    this._getWorkouts, {
    ExerciseRepository? exercises,
    Stream<void>? changes,
  }) : _exercises = exercises,
       super(const WorkoutsState()) {
    _changes = changes?.listen((_) => load());
  }

  final GetWorkoutsUseCase _getWorkouts;
  final ExerciseRepository? _exercises;
  StreamSubscription<void>? _changes;

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }

  /// Thumbnail of each plan's first exercise, used as card artwork.
  Future<Map<String, String>> _covers(List<Workout> workouts) async {
    final exercises = _exercises;
    if (exercises == null) return const <String, String>{};
    final covers = <String, String>{};
    for (final workout in workouts) {
      if (workout.exercises.isEmpty) continue;
      final first = await exercises.getExerciseById(
        workout.exercises.first.exerciseId,
      );
      if (first != null) covers[workout.id] = first.thumbnailAsset;
    }
    return covers;
  }

  Future<void> load() async {
    emit(state.copyWith(status: WorkoutsStatus.loading, errorMessage: null));
    try {
      final workouts = await _getWorkouts();
      final covers = await _covers(workouts);
      emit(
        state.copyWith(
          status: WorkoutsStatus.loaded,
          workouts: workouts,
          covers: covers,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: WorkoutsStatus.error,
          errorMessage:
              'Could not load workout plans. Check your connection and try again.',
        ),
      );
    }
  }
}
