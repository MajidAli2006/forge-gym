import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/core/errors/failures.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/custom_workout_repository.dart';
import 'package:forge_gym/features/workouts/domain/usecases/save_custom_workout_usecase.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/routine_editor_state.dart';

/// Builds or edits one member routine. Holds the draft; the use case
/// validates and derives the rest on save.
class RoutineEditorCubit extends Cubit<RoutineEditorState> {
  RoutineEditorCubit({
    required SaveCustomWorkoutUseCase saveCustomWorkout,
    required CustomWorkoutRepository customWorkouts,
    required ExerciseRepository exercises,
  }) : _save = saveCustomWorkout,
       _custom = customWorkouts,
       _exercises = exercises,
       super(const RoutineEditorState());

  final SaveCustomWorkoutUseCase _save;
  final CustomWorkoutRepository _custom;
  final ExerciseRepository _exercises;

  /// Starts a blank draft, or loads [routineId] for editing.
  Future<void> start({String? routineId}) async {
    if (routineId == null) {
      emit(const RoutineEditorState(status: RoutineEditorStatus.editing));
      return;
    }
    final routine = await _custom.getById(routineId);
    if (routine == null) {
      emit(
        const RoutineEditorState(
          status: RoutineEditorStatus.error,
          errorMessage: 'This routine no longer exists.',
        ),
      );
      return;
    }
    final items = <RoutineItem>[];
    for (final item in routine.exercises) {
      final exercise = await _exercises.getExerciseById(item.exerciseId);
      if (exercise == null) continue;
      items.add(
        RoutineItem(
          exercise: exercise,
          sets: item.sets,
          reps: item.reps,
          restSeconds: item.restSeconds,
        ),
      );
    }
    emit(
      RoutineEditorState(
        status: RoutineEditorStatus.editing,
        id: routine.id,
        name: routine.name,
        notes: routine.description,
        items: items,
      ),
    );
  }

  void setName(String value) => emit(state.copyWith(name: value));

  void setNotes(String value) => emit(state.copyWith(notes: value));

  /// Library exercises not yet in the draft, for the picker.
  Future<List<Exercise>> availableExercises({String query = ''}) async {
    final all = await _exercises.getExercises(query: query);
    final chosen = state.items.map((i) => i.exercise.id).toSet();
    return all.where((e) => !chosen.contains(e.id)).toList();
  }

  void addExercise(Exercise exercise) {
    if (state.items.any((i) => i.exercise.id == exercise.id)) return;
    if (state.items.length >= SaveCustomWorkoutUseCase.maxExercises) {
      emit(
        state.copyWith(
          errorMessage:
              'A routine can have up to '
              '${SaveCustomWorkoutUseCase.maxExercises} exercises.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        items: <RoutineItem>[
          ...state.items,
          RoutineItem.fromExercise(exercise),
        ],
      ),
    );
  }

  void removeAt(int index) {
    final items = List<RoutineItem>.of(state.items)..removeAt(index);
    emit(state.copyWith(items: items));
  }

  void move(int from, int to) {
    final items = List<RoutineItem>.of(state.items);
    final item = items.removeAt(from);
    items.insert(to > from ? to - 1 : to, item);
    emit(state.copyWith(items: items));
  }

  void updateItem(int index, {int? sets, int? reps, int? restSeconds}) {
    final items = List<RoutineItem>.of(state.items);
    items[index] = items[index].copyWith(
      sets: sets?.clamp(1, 10),
      reps: reps?.clamp(1, 600),
      restSeconds: restSeconds?.clamp(0, 600),
    );
    emit(state.copyWith(items: items));
  }

  Future<void> save() async {
    if (state.status == RoutineEditorStatus.saving) return;
    emit(state.copyWith(status: RoutineEditorStatus.saving));
    try {
      final workout = await _save(
        id: state.id,
        name: state.name,
        description: state.notes,
        exercises: <WorkoutExercise>[
          for (var i = 0; i < state.items.length; i++)
            WorkoutExercise(
              exerciseId: state.items[i].exercise.id,
              sets: state.items[i].sets,
              reps: state.items[i].reps,
              restSeconds: state.items[i].restSeconds,
              order: i,
            ),
        ],
      );
      emit(
        state.copyWith(
          status: RoutineEditorStatus.saved,
          id: workout.id,
          savedId: workout.id,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: RoutineEditorStatus.editing,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: RoutineEditorStatus.editing,
          errorMessage: 'Could not save the routine. Please try again.',
        ),
      );
    }
  }
}
