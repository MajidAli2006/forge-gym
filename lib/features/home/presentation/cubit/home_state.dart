import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/challenges/domain/entities/challenge.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/home/domain/entities/announcement.dart';
import 'package:forge_gym/features/progress/domain/entities/progress_summary.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';

/// Lifecycle of the home dashboard data load.
enum HomeStatus { initial, loading, loaded, error }

/// Everything the home dashboard renders. Immutable; the cubit rebuilds it
/// on every load.
class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.userName = 'there',
    this.todayWorkout,
    this.hasResumableWorkout = false,
    this.recommended = const <Workout>[],
    this.recentExercises = const <Exercise>[],
    this.weeklySummary,
    this.announcements = const <Announcement>[],
    this.featuredExercises = const <Exercise>[],
    this.workoutCovers = const <String, String>{},
    this.challenges = const <ChallengeProgress>[],
    this.errorMessage,
  });

  final HomeStatus status;
  final String userName;
  final Workout? todayWorkout;
  final bool hasResumableWorkout;
  final List<Workout> recommended;
  final List<Exercise> recentExercises;
  final ProgressSummary? weeklySummary;
  final List<Announcement> announcements;

  /// Demo clips promoted on the dashboard ("Learn perfect form").
  final List<Exercise> featuredExercises;

  /// Workout id → thumbnail of its first exercise (card artwork).
  final Map<String, String> workoutCovers;

  /// Active challenges first, then a few to join.
  final List<ChallengeProgress> challenges;
  final String? errorMessage;

  HomeState copyWith({
    HomeStatus? status,
    String? userName,
    Workout? todayWorkout,
    bool? hasResumableWorkout,
    List<Workout>? recommended,
    List<Exercise>? recentExercises,
    ProgressSummary? weeklySummary,
    List<Announcement>? announcements,
    List<Exercise>? featuredExercises,
    Map<String, String>? workoutCovers,
    List<ChallengeProgress>? challenges,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      userName: userName ?? this.userName,
      todayWorkout: todayWorkout ?? this.todayWorkout,
      hasResumableWorkout: hasResumableWorkout ?? this.hasResumableWorkout,
      recommended: recommended ?? this.recommended,
      recentExercises: recentExercises ?? this.recentExercises,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      announcements: announcements ?? this.announcements,
      featuredExercises: featuredExercises ?? this.featuredExercises,
      workoutCovers: workoutCovers ?? this.workoutCovers,
      challenges: challenges ?? this.challenges,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    userName,
    todayWorkout,
    hasResumableWorkout,
    recommended,
    recentExercises,
    weeklySummary,
    announcements,
    featuredExercises,
    workoutCovers,
    challenges,
    errorMessage,
  ];
}
