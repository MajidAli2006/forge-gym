import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/features/auth/domain/repositories/auth_repository.dart';
import 'package:forge_gym/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:forge_gym/features/challenges/domain/usecases/get_challenge_progress_usecase.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:forge_gym/features/home/data/datasources/announcement_local_datasource.dart';
import 'package:forge_gym/features/home/data/repositories/mock_announcement_repository.dart';
import 'package:forge_gym/features/home/domain/repositories/announcement_repository.dart';
import 'package:forge_gym/features/home/domain/usecases/get_announcements_usecase.dart';
import 'package:forge_gym/features/home/presentation/cubit/home_cubit.dart';
import 'package:forge_gym/features/progress/domain/usecases/get_progress_summary_usecase.dart';
import 'package:forge_gym/features/workouts/domain/repositories/active_workout_repository.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_workouts_usecase.dart';

/// Registers the home feature's object graph.
///
/// Call after the auth, exercises, workouts, and progress modules — home
/// resolves their contracts from getIt.
Future<void> registerHomeDependencies() async {
  getIt.registerLazySingleton<AnnouncementLocalDataSource>(
    () => const AssetAnnouncementDataSource(),
  );
  getIt.registerLazySingleton<AnnouncementRepository>(
    () => MockAnnouncementRepository(getIt<AnnouncementLocalDataSource>()),
  );
  getIt.registerLazySingleton<GetAnnouncementsUseCase>(
    () => GetAnnouncementsUseCase(getIt<AnnouncementRepository>()),
  );
  getIt.registerFactory<HomeCubit>(
    () => HomeCubit(
      authRepository: getIt<AuthRepository>(),
      getWorkoutsUseCase: getIt<GetWorkoutsUseCase>(),
      activeWorkoutRepository: getIt<ActiveWorkoutRepository>(),
      workoutHistoryRepository: getIt<WorkoutHistoryRepository>(),
      exerciseRepository: getIt<ExerciseRepository>(),
      getProgressSummaryUseCase: getIt<GetProgressSummaryUseCase>(),
      getAnnouncementsUseCase: getIt<GetAnnouncementsUseCase>(),
      getChallengeProgress: getIt<GetChallengeProgressUseCase>(),
      challengeEnrollments: getIt<ChallengeEnrollmentRepository>(),
    ),
  );
}
