import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/core/notifications/notification_service.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:forge_gym/features/workouts/data/datasources/workout_local_datasource.dart';
import 'package:forge_gym/features/workouts/data/repositories/composite_workout_repository.dart';
import 'package:forge_gym/features/workouts/data/repositories/local_active_workout_repository.dart';
import 'package:forge_gym/features/workouts/data/repositories/local_workout_history_repository.dart';
import 'package:forge_gym/features/workouts/data/repositories/mock_workout_repository.dart';
import 'package:forge_gym/features/workouts/data/repositories/prefs_custom_workout_repository.dart';
import 'package:forge_gym/features/workouts/domain/repositories/active_workout_repository.dart';
import 'package:forge_gym/features/workouts/domain/repositories/custom_workout_repository.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_history_repository.dart';
import 'package:forge_gym/features/workouts/domain/repositories/workout_repository.dart';
import 'package:forge_gym/features/workouts/domain/usecases/clear_active_workout_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/delete_custom_workout_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_active_workout_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_workout_by_id_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_workout_history_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_workouts_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/quick_log_set_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/save_active_workout_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/save_completed_workout_usecase.dart';
import 'package:forge_gym/features/workouts/domain/usecases/save_custom_workout_usecase.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/routine_editor_cubit.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workout_detail_cubit.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workout_session_cubit.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workouts_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registers the workouts object graph.
///
/// Called from `configureDependencies()` in `injection.dart`.
/// [SharedPreferences] and [ExerciseRepository] are registered by the app
/// bootstrap and the exercises feature respectively.
Future<void> registerWorkoutsDependencies() async {
  // --- Data --------------------------------------------------------------
  getIt.registerLazySingleton<WorkoutLocalDataSource>(
    AssetWorkoutLocalDataSource.new,
  );
  getIt.registerLazySingleton<CustomWorkoutRepository>(
    () => PrefsCustomWorkoutRepository(getIt<SharedPreferences>()),
  );
  // One catalogue: the member's own routines first, then the gym's plans.
  getIt.registerLazySingleton<WorkoutRepository>(
    () => CompositeWorkoutRepository(
      plans: MockWorkoutRepository(getIt<WorkoutLocalDataSource>()),
      custom: getIt<CustomWorkoutRepository>(),
    ),
  );
  getIt.registerLazySingleton<ActiveWorkoutRepository>(
    () => LocalActiveWorkoutRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<WorkoutHistoryRepository>(
    () => LocalWorkoutHistoryRepository(getIt<SharedPreferences>()),
  );

  // --- Domain ------------------------------------------------------------
  getIt.registerLazySingleton(
    () => GetWorkoutsUseCase(getIt<WorkoutRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetWorkoutByIdUseCase(getIt<WorkoutRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetActiveWorkoutUseCase(getIt<ActiveWorkoutRepository>()),
  );
  getIt.registerLazySingleton(
    () => SaveActiveWorkoutUseCase(getIt<ActiveWorkoutRepository>()),
  );
  getIt.registerLazySingleton(
    () => ClearActiveWorkoutUseCase(getIt<ActiveWorkoutRepository>()),
  );
  getIt.registerLazySingleton(
    () => SaveCompletedWorkoutUseCase(getIt<WorkoutHistoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetWorkoutHistoryUseCase(getIt<WorkoutHistoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => QuickLogSetUseCase(getIt<WorkoutHistoryRepository>()),
  );
  getIt.registerLazySingleton(
    () => SaveCustomWorkoutUseCase(
      getIt<CustomWorkoutRepository>(),
      getIt<ExerciseRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => DeleteCustomWorkoutUseCase(getIt<CustomWorkoutRepository>()),
  );

  // --- Presentation ------------------------------------------------------
  // Factories: one cubit per screen, never shared screen state.
  getIt.registerFactory(
    () => WorkoutsCubit(
      getIt<GetWorkoutsUseCase>(),
      exercises: getIt<ExerciseRepository>(),
      changes: getIt<CustomWorkoutRepository>().changes,
    ),
  );
  getIt.registerFactory(
    () => WorkoutDetailCubit(
      getIt<GetWorkoutByIdUseCase>(),
      exercises: getIt<ExerciseRepository>(),
      deleteCustomWorkout: getIt<DeleteCustomWorkoutUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => RoutineEditorCubit(
      saveCustomWorkout: getIt<SaveCustomWorkoutUseCase>(),
      customWorkouts: getIt<CustomWorkoutRepository>(),
      exercises: getIt<ExerciseRepository>(),
    ),
  );
  getIt.registerFactory(
    () => WorkoutSessionCubit(
      getWorkoutById: getIt<GetWorkoutByIdUseCase>(),
      exerciseRepository: getIt<ExerciseRepository>(),
      getActiveWorkout: getIt<GetActiveWorkoutUseCase>(),
      saveActiveWorkout: getIt<SaveActiveWorkoutUseCase>(),
      clearActiveWorkout: getIt<ClearActiveWorkoutUseCase>(),
      saveCompletedWorkout: getIt<SaveCompletedWorkoutUseCase>(),
      notifications: getIt<NotificationService>(),
    ),
  );
}
