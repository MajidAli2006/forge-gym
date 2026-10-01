import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/core/notifications/notification_service.dart';
import 'package:forge_gym/core/notifications/push_service.dart';
import 'package:forge_gym/features/auth/domain/repositories/auth_repository.dart';
import 'package:forge_gym/features/auth/domain/usecases/auth_usecases.dart';
import 'package:forge_gym/features/profile/data/repositories/prefs_notification_preferences_repository.dart';
import 'package:forge_gym/features/profile/domain/repositories/notification_preferences_repository.dart';
import 'package:forge_gym/features/profile/domain/usecases/sync_workout_reminder_usecase.dart';
import 'package:forge_gym/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:forge_gym/features/progress/domain/usecases/get_weight_history_usecase.dart';
import 'package:forge_gym/features/progress/domain/usecases/log_weight_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registers the profile feature's object graph.
///
/// Call after the auth module — the cubit resolves [AuthRepository] and
/// [UpdateProfileUseCase] from getIt.
Future<void> registerProfileDependencies() async {
  getIt.registerLazySingleton<NotificationPreferencesRepository>(
    () => PrefsNotificationPreferencesRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<SyncWorkoutReminderUseCase>(
    () => SyncWorkoutReminderUseCase(
      getIt<NotificationService>(),
      push: getIt<PushService>(),
    ),
  );
  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(
      authRepository: getIt<AuthRepository>(),
      updateProfileUseCase: getIt<UpdateProfileUseCase>(),
      preferencesRepository: getIt<NotificationPreferencesRepository>(),
      logWeightUseCase: getIt<LogWeightUseCase>(),
      getWeightHistoryUseCase: getIt<GetWeightHistoryUseCase>(),
      syncWorkoutReminder: getIt<SyncWorkoutReminderUseCase>(),
    ),
  );
}
