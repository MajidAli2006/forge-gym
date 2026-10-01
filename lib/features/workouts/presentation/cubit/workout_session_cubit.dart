import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/core/notifications/notification_service.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:forge_gym/features/workouts/domain/entities/active_workout.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/usecases/clear_active_workout_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_active_workout_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_workout_by_id_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/save_active_workout_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/save_completed_workout_usecase.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workout_session_state.dart';

/// Owns the live workout session: current exercise/set, completed sets,
/// the rest timer, and persistence.
///
/// Every mutation is persisted immediately so the session survives
/// backgrounding, phone lock, and process termination. The rest timer is
/// in-memory only — a restored session never resumes mid-rest.
class WorkoutSessionCubit extends Cubit<WorkoutSessionState> {
  WorkoutSessionCubit({
    required GetWorkoutByIdUseCase getWorkoutById,
    required ExerciseRepository exerciseRepository,
    required GetActiveWorkoutUseCase getActiveWorkout,
    required SaveActiveWorkoutUseCase saveActiveWorkout,
    required ClearActiveWorkoutUseCase clearActiveWorkout,
    required SaveCompletedWorkoutUseCase saveCompletedWorkout,
    NotificationService notifications = const NoopNotificationService(),
  }) : _notifications = notifications,
       _getWorkoutById = getWorkoutById,
       _exerciseRepository = exerciseRepository,
       _getActiveWorkout = getActiveWorkout,
       _saveActiveWorkout = saveActiveWorkout,
       _clearActiveWorkout = clearActiveWorkout,
       _saveCompletedWorkout = saveCompletedWorkout,
       super(const WorkoutSessionState());

  final GetWorkoutByIdUseCase _getWorkoutById;
  final ExerciseRepository _exerciseRepository;
  final GetActiveWorkoutUseCase _getActiveWorkout;
  final SaveActiveWorkoutUseCase _saveActiveWorkout;
  final ClearActiveWorkoutUseCase _clearActiveWorkout;
  final SaveCompletedWorkoutUseCase _saveCompletedWorkout;
  final NotificationService _notifications;

  Timer? _restTimer;

  /// Restores a persisted session, if any. The screen decides whether to
  /// resume it or start fresh.
  Future<void> initialize() async {
    emit(const WorkoutSessionState(status: WorkoutSessionStatus.loading));
    try {
      final persisted = await _getActiveWorkout();
      if (persisted != null) {
        emit(
          WorkoutSessionState(
            status: WorkoutSessionStatus.active,
            session: persisted,
          ),
        );
      } else {
        emit(const WorkoutSessionState(status: WorkoutSessionStatus.initial));
      }
    } catch (_) {
      emit(
        const WorkoutSessionState(
          status: WorkoutSessionStatus.initial,
          errorMessage: 'Could not restore your workout session.',
        ),
      );
    }
  }

  /// Builds a fresh session from a workout plan, resolving exercise names.
  Future<void> startWorkout(String workoutId) async {
    _restTimer?.cancel();
    emit(state.copyWith(status: WorkoutSessionStatus.loading));
    try {
      final workout = await _getWorkoutById(workoutId);
      if (workout == null) {
        emit(
          state.copyWith(
            status: WorkoutSessionStatus.initial,
            errorMessage: 'Workout not found.',
          ),
        );
        return;
      }
      final exercises = <ActiveExercise>[];
      for (final item in workout.exercises) {
        final exercise = await _exerciseRepository.getExerciseById(
          item.exerciseId,
        );
        exercises.add(
          ActiveExercise(
            exerciseId: item.exerciseId,
            exerciseName: exercise?.name ?? item.exerciseId,
            targetSets: item.sets,
            targetReps: item.reps,
            restSeconds: item.restSeconds,
            tracking: exercise?.tracking ?? TrackingType.weightedReps,
            sets: List<ActiveSet>.generate(
              item.sets,
              (_) => ActiveSet(reps: item.reps, weightKg: 0),
            ),
          ),
        );
      }
      final now = DateTime.now();
      final session = ActiveWorkout(
        id: 'active-${now.microsecondsSinceEpoch}',
        workoutId: workout.id,
        workoutName: workout.name,
        startedAt: now,
        exercises: exercises,
      );
      await _saveActiveWorkout(session);
      emit(
        WorkoutSessionState(
          status: WorkoutSessionStatus.active,
          session: session,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: WorkoutSessionStatus.initial,
          errorMessage: 'Could not start the workout. Please try again.',
        ),
      );
    }
  }

  /// Logs the current set and starts the rest countdown.
  Future<void> completeSet({
    required int reps,
    required double weightKg,
  }) async {
    final session = state.session;
    if (session == null || state.status != WorkoutSessionStatus.active) return;
    final updated = session.completeCurrentSet(reps: reps, weightKg: weightKg);
    await _saveActiveWorkout(updated);
    final restSeconds = updated.currentExercise.restSeconds;
    emit(state.copyWith(session: updated, restSecondsLeft: restSeconds));
    _beginRest(restSeconds);
    // Fires only if the countdown ends while the app is in the background;
    // every in-app path that ends the rest cancels it first.
    unawaited(
      _notifications.scheduleRestFinished(
        after: Duration(seconds: restSeconds),
        upNext: _upNextLabel(updated),
      ),
    );
  }

  static String _upNextLabel(ActiveWorkout session) {
    final exercise = session.currentExercise;
    if (session.currentSetIndex + 1 < exercise.targetSets) {
      return '${exercise.exerciseName} — set ${session.currentSetIndex + 2} '
          'of ${exercise.targetSets}';
    }
    if (session.currentExerciseIndex + 1 < session.exercises.length) {
      return 'Next up: '
          '${session.exercises[session.currentExerciseIndex + 1].exerciseName}';
    }
    return 'Last set done — finish your workout.';
  }

  void _beginRest(int seconds) {
    _restTimer?.cancel();
    if (seconds <= 0) {
      unawaited(advance());
      return;
    }
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = state.restSecondsLeft - 1;
      if (left <= 0) {
        _restTimer?.cancel();
        unawaited(advance());
      } else {
        emit(state.copyWith(restSecondsLeft: left));
      }
    });
  }

  /// Adds 15 seconds to the running rest timer.
  void addRest15Seconds() {
    if (state.restSecondsLeft <= 0) return;
    final left = state.restSecondsLeft + 15;
    emit(state.copyWith(restSecondsLeft: left));
    final session = state.session;
    if (session != null) {
      unawaited(
        _notifications.scheduleRestFinished(
          after: Duration(seconds: left),
          upNext: _upNextLabel(session),
        ),
      );
    }
  }

  /// Skips the rest and moves on immediately.
  Future<void> skipRest() async {
    _restTimer?.cancel();
    await advance();
  }

  /// Moves to the next set, next exercise, or finishes the workout.
  Future<void> advance() async {
    _restTimer?.cancel();
    unawaited(_notifications.cancelRestFinished());
    final session = state.session;
    if (session == null || state.status != WorkoutSessionStatus.active) return;
    final next = session.advance();
    if (next == null) {
      await finishWorkout();
      return;
    }
    await _saveActiveWorkout(next);
    emit(state.copyWith(session: next, restSecondsLeft: 0));
  }

  Future<void> previousExercise() async {
    final session = state.session;
    if (session == null || state.status != WorkoutSessionStatus.active) return;
    await _goToExercise(session.currentExerciseIndex - 1);
  }

  Future<void> nextExercise() async {
    final session = state.session;
    if (session == null || state.status != WorkoutSessionStatus.active) return;
    await _goToExercise(session.currentExerciseIndex + 1);
  }

  Future<void> _goToExercise(int index) async {
    final session = state.session;
    if (session == null) return;
    _restTimer?.cancel();
    final moved = session.moveToExercise(index);
    await _saveActiveWorkout(moved);
    emit(state.copyWith(session: moved, restSecondsLeft: 0));
  }

  /// Finishes the session: builds the history record (volume = Σ reps×kg),
  /// saves it, clears the active session.
  Future<void> finishWorkout() async {
    _restTimer?.cancel();
    unawaited(_notifications.cancelRestFinished());
    final session = state.session;
    if (session == null) return;
    final finishedAt = DateTime.now();
    final completedExercises = <CompletedExercise>[];
    var volume = 0.0;
    for (final exercise in session.exercises) {
      final doneSets = <PerformedSet>[];
      for (final set in exercise.sets) {
        if (!set.completed) continue;
        doneSets.add(
          PerformedSet(
            setNumber: doneSets.length + 1,
            reps: set.reps,
            weightKg: set.weightKg,
          ),
        );
        // Timed holds carry no load; bodyweight reps only count when
        // extra weight was added (e.g. a weighted pull-up).
        if (!exercise.tracking.isTimed) volume += set.reps * set.weightKg;
      }
      if (doneSets.isNotEmpty) {
        completedExercises.add(
          CompletedExercise(
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.exerciseName,
            sets: doneSets,
            tracking: exercise.tracking,
          ),
        );
      }
    }
    final completed = CompletedWorkout(
      id: 'cw-${finishedAt.microsecondsSinceEpoch}',
      workoutId: session.workoutId,
      workoutName: session.workoutName,
      startedAt: session.startedAt,
      finishedAt: finishedAt,
      durationSeconds: finishedAt.difference(session.startedAt).inSeconds,
      totalVolumeKg: volume,
      exercises: completedExercises,
    );
    await _saveCompletedWorkout(completed);
    await _clearActiveWorkout();
    emit(
      WorkoutSessionState(
        status: WorkoutSessionStatus.finished,
        lastCompleted: completed,
      ),
    );
  }

  /// Discards the session without saving to history.
  Future<void> discardWorkout() async {
    _restTimer?.cancel();
    unawaited(_notifications.cancelRestFinished());
    await _clearActiveWorkout();
    emit(const WorkoutSessionState(status: WorkoutSessionStatus.initial));
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  @override
  Future<void> close() {
    _restTimer?.cancel();
    return super.close();
  }
}
