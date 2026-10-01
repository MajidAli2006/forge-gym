import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';
import 'package:forge_gym/features/auth/domain/repositories/auth_repository.dart';
import 'package:forge_gym/features/challenges/domain/entities/challenge.dart';
import 'package:forge_gym/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:forge_gym/features/challenges/domain/usecases/get_challenge_progress_usecase.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:forge_gym/features/home/domain/entities/announcement.dart';
import 'package:forge_gym/features/home/domain/usecases/get_announcements_usecase.dart';
import 'package:forge_gym/features/home/presentation/cubit/home_state.dart';
import 'package:forge_gym/features/progress/domain/entities/progress_summary.dart';
import 'package:forge_gym/features/progress/domain/usecases/get_progress_summary_usecase.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:forge_gym/features/workouts/domain/repositories/active_workout_repository.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_workouts_usecase.dart';

/// Assembles the home dashboard from the other features' domain contracts.
///
/// Home owns no workout/exercise/auth data of its own — it orchestrates
/// their use cases. Each dependency is constructor-injected.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required AuthRepository authRepository,
    required GetWorkoutsUseCase getWorkoutsUseCase,
    required ActiveWorkoutRepository activeWorkoutRepository,
    required WorkoutHistoryRepository workoutHistoryRepository,
    required ExerciseRepository exerciseRepository,
    required GetProgressSummaryUseCase getProgressSummaryUseCase,
    required GetAnnouncementsUseCase getAnnouncementsUseCase,
    required GetChallengeProgressUseCase getChallengeProgress,
    required ChallengeEnrollmentRepository challengeEnrollments,
  }) : _getChallengeProgress = getChallengeProgress,
       _authRepository = authRepository,
       _getWorkoutsUseCase = getWorkoutsUseCase,
       _activeWorkoutRepository = activeWorkoutRepository,
       _workoutHistoryRepository = workoutHistoryRepository,
       _exerciseRepository = exerciseRepository,
       _getProgressSummaryUseCase = getProgressSummaryUseCase,
       _getAnnouncementsUseCase = getAnnouncementsUseCase,
       super(const HomeState()) {
    // Finished workouts change the weekly stats and recent exercises, so
    // refresh whenever history is written (the tab stays alive in the
    // shell's IndexedStack and would otherwise show stale numbers).
    _historySubscription = _workoutHistoryRepository.changes.listen(
      (_) => refresh(),
    );
    _enrollmentSubscription = challengeEnrollments.changes.listen(
      (_) => refresh(),
    );
  }

  final AuthRepository _authRepository;
  final GetWorkoutsUseCase _getWorkoutsUseCase;
  final ActiveWorkoutRepository _activeWorkoutRepository;
  final WorkoutHistoryRepository _workoutHistoryRepository;
  final ExerciseRepository _exerciseRepository;
  final GetProgressSummaryUseCase _getProgressSummaryUseCase;
  final GetAnnouncementsUseCase _getAnnouncementsUseCase;
  final GetChallengeProgressUseCase _getChallengeProgress;

  StreamSubscription<void>? _historySubscription;
  StreamSubscription<void>? _enrollmentSubscription;

  /// Loads every dashboard section. Independent sources are fetched in
  /// parallel; failures surface as a single friendly error state.
  Future<void> load() => _load(showLoading: true);

  /// Reloads in place without flashing the loading state. Used after
  /// history changes and for pull-to-refresh.
  Future<void> refresh() => _load(showLoading: false);

  Future<void> _load({required bool showLoading}) async {
    if (showLoading) emit(state.copyWith(status: HomeStatus.loading));
    try {
      final userFuture = _authRepository.currentUser();
      final workoutsFuture = _getWorkoutsUseCase();
      final resumableFuture = _activeWorkoutRepository.load();
      final historyFuture = _workoutHistoryRepository.getHistory();
      final summaryFuture = _getProgressSummaryUseCase();
      final announcementsFuture = _getAnnouncementsUseCase();

      final User? user = await userFuture;
      final List<Workout> workouts = await workoutsFuture;
      final ActiveWorkout? resumable = await resumableFuture;
      final List<CompletedWorkout> history = await historyFuture;
      final ProgressSummary summary = await summaryFuture;
      final List<Announcement> announcements = await announcementsFuture;

      final recentExercises = await _recentExercises(history);

      final today = _todayWorkoutFor(user, workouts);
      final recommended = workouts.where((w) => w != today).take(5).toList();
      final covers = await _covers(<Workout>[?today, ...recommended]);
      final featured = await _featured(today);
      final challenges = await _getChallengeProgress();
      final active = challenges.where((c) => c.isActive).toList();
      final toJoin = challenges
          .where((c) => c.status == ChallengeStatus.available)
          .take(active.isEmpty ? 3 : 2)
          .toList();
      emit(
        state.copyWith(
          status: HomeStatus.loaded,
          userName: user?.name ?? 'there',
          todayWorkout: today,
          hasResumableWorkout: resumable != null,
          recommended: recommended,
          recentExercises: recentExercises,
          weeklySummary: summary,
          announcements: announcements,
          featuredExercises: featured,
          workoutCovers: covers,
          challenges: <ChallengeProgress>[...active, ...toJoin],
        ),
      );
    } catch (_) {
      if (!showLoading && state.status == HomeStatus.loaded) return;
      emit(
        state.copyWith(
          status: HomeStatus.error,
          errorMessage:
              'Could not load your dashboard. Check your connection and try again.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _historySubscription?.cancel();
    _enrollmentSubscription?.cancel();
    return super.close();
  }

  /// Thumbnail of each plan's first exercise, for card artwork.
  Future<Map<String, String>> _covers(List<Workout> workouts) async {
    final covers = <String, String>{};
    for (final workout in workouts) {
      if (workout.exercises.isEmpty) continue;
      final first = await _exerciseRepository.getExerciseById(
        workout.exercises.first.exerciseId,
      );
      if (first != null) covers[workout.id] = first.thumbnailAsset;
    }
    return covers;
  }

  /// Demo clips worth watching today: the exercises in today's plan,
  /// topped up from the library so the row is never empty.
  Future<List<Exercise>> _featured(Workout? today) async {
    final featured = <Exercise>[];
    for (final item in today?.exercises ?? const <WorkoutExercise>[]) {
      final exercise = await _exerciseRepository.getExerciseById(
        item.exerciseId,
      );
      if (exercise != null && exercise.videoAsset != null) {
        featured.add(exercise);
      }
      if (featured.length >= 6) break;
    }
    if (featured.length < 4) {
      final all = await _exerciseRepository.getExercises();
      for (final exercise in all) {
        if (featured.length >= 6) break;
        if (exercise.videoAsset == null) continue;
        if (featured.any((e) => e.id == exercise.id)) continue;
        featured.add(exercise);
      }
    }
    return featured;
  }

  /// The first plan at the member's own level (beginner → beginner plan);
  /// falls back to the first plan when nothing matches.
  static Workout? _todayWorkoutFor(User? user, List<Workout> workouts) {
    if (workouts.isEmpty) return null;
    final level = user?.fitnessLevel;
    if (level == null) return workouts.first;
    for (final workout in workouts) {
      if (workout.difficulty.name == level.name) return workout;
    }
    return workouts.first;
  }

  /// Distinct exercises from the last three finished workouts, resolved to
  /// full [Exercise] objects for display. Unknown ids are skipped.
  Future<List<Exercise>> _recentExercises(
    List<CompletedWorkout> history,
  ) async {
    final ids = <String>[];
    for (final workout in history.take(3)) {
      for (final exercise in workout.exercises) {
        if (!ids.contains(exercise.exerciseId)) ids.add(exercise.exerciseId);
      }
    }
    final recent = <Exercise>[];
    for (final id in ids.take(6)) {
      final exercise = await _exerciseRepository.getExerciseById(id);
      if (exercise != null) recent.add(exercise);
    }
    return recent;
  }
}
