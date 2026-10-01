import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/features/auth/domain/repositories/auth_repository.dart';
import 'package:forge_gym/features/auth/domain/usecases/auth_usecases.dart';
import 'package:forge_gym/features/progress/data/repositories/prefs_weight_repository.dart';
import 'package:forge_gym/features/progress/domain/repositories/weight_repository.dart';
import 'package:forge_gym/features/progress/domain/usecases/get_progress_summary_usecase.dart';
import 'package:forge_gym/features/progress/domain/usecases/get_weight_history_usecase.dart';
import 'package:forge_gym/features/progress/domain/usecases/log_weight_usecase.dart';
import 'package:forge_gym/features/progress/presentation/cubit/progress_cubit.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registers the progress feature's object graph.
///
/// Call after the workouts module — the summary use case resolves
/// [WorkoutHistoryRepository] from getIt.
Future<void> registerProgressDependencies() async {
  getIt.registerLazySingleton<WeightRepository>(
    () => PrefsWeightRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<GetWeightHistoryUseCase>(
    () => GetWeightHistoryUseCase(getIt<WeightRepository>()),
  );
  getIt.registerLazySingleton<LogWeightUseCase>(
    () => LogWeightUseCase(getIt<WeightRepository>()),
  );
  getIt.registerLazySingleton<GetProgressSummaryUseCase>(
    () => GetProgressSummaryUseCase(getIt<WorkoutHistoryRepository>()),
  );
  getIt.registerFactory<ProgressCubit>(
    () => ProgressCubit(
      getProgressSummaryUseCase: getIt<GetProgressSummaryUseCase>(),
      workoutHistoryRepository: getIt<WorkoutHistoryRepository>(),
      weightRepository: getIt<WeightRepository>(),
      getWeightHistoryUseCase: getIt<GetWeightHistoryUseCase>(),
      logWeightUseCase: getIt<LogWeightUseCase>(),
      authRepository: getIt<AuthRepository>(),
      updateProfileUseCase: getIt<UpdateProfileUseCase>(),
    ),
  );
}
