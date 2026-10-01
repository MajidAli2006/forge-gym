import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/features/exercises/data/datasources/exercise_local_datasource.dart';
import 'package:forge_gym/features/exercises/data/repositories/mock_exercise_repository.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:forge_gym/features/exercises/domain/usecases/get_exercise_by_id_usecase.dart';
import 'package:forge_gym/features/exercises/domain/usecases/get_exercises_usecase.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercise_detail_cubit.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercises_cubit.dart';
import 'package:forge_gym/features/workouts/domain/usecases/quick_log_set_usecase.dart';

/// Registers the exercise feature's object graph. Called from
/// `configureDependencies()` — the only place `getIt` is touched.
Future<void> registerExercisesDependencies() async {
  getIt.registerLazySingleton<ExerciseLocalDataSource>(
    AssetExerciseLocalDataSource.new,
  );
  getIt.registerLazySingleton<ExerciseRepository>(
    () => MockExerciseRepository(getIt<ExerciseLocalDataSource>()),
  );
  getIt.registerLazySingleton<GetExercisesUseCase>(
    () => GetExercisesUseCase(getIt<ExerciseRepository>()),
  );
  getIt.registerLazySingleton<GetExerciseByIdUseCase>(
    () => GetExerciseByIdUseCase(getIt<ExerciseRepository>()),
  );
  getIt.registerFactory<ExercisesCubit>(
    () => ExercisesCubit(getIt<GetExercisesUseCase>()),
  );
  getIt.registerFactory<ExerciseDetailCubit>(
    () => ExerciseDetailCubit(
      getIt<GetExerciseByIdUseCase>(),
      // Registered by the workouts module; resolved lazily per screen.
      quickLogSet: getIt<QuickLogSetUseCase>(),
    ),
  );
}
