import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/features/challenges/data/datasources/challenge_local_datasource.dart';
import 'package:forge_gym/features/challenges/data/repositories/mock_challenge_repository.dart';
import 'package:forge_gym/features/challenges/data/repositories/prefs_challenge_enrollment_repository.dart';
import 'package:forge_gym/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:forge_gym/features/challenges/domain/usecases/get_challenge_progress_usecase.dart';
import 'package:forge_gym/features/challenges/presentation/cubit/challenges_cubit.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registers the challenges feature. Call after the workouts module — the
/// progress use case reads finished workouts through its domain contract.
Future<void> registerChallengesDependencies() async {
  getIt.registerLazySingleton<ChallengeLocalDataSource>(
    () => const AssetChallengeDataSource(),
  );
  getIt.registerLazySingleton<ChallengeRepository>(
    () => MockChallengeRepository(getIt<ChallengeLocalDataSource>()),
  );
  getIt.registerLazySingleton<ChallengeEnrollmentRepository>(
    () => PrefsChallengeEnrollmentRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<GetChallengeProgressUseCase>(
    () => GetChallengeProgressUseCase(
      challenges: getIt<ChallengeRepository>(),
      enrollments: getIt<ChallengeEnrollmentRepository>(),
      history: getIt<WorkoutHistoryRepository>(),
    ),
  );
  getIt.registerFactory<ChallengesCubit>(
    () => ChallengesCubit(
      getProgress: getIt<GetChallengeProgressUseCase>(),
      enrollments: getIt<ChallengeEnrollmentRepository>(),
      history: getIt<WorkoutHistoryRepository>(),
    ),
  );
}
