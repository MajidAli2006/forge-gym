import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:forge_gym/app/bootstrap/app_environment.dart';
import 'package:forge_gym/app/routing/app_router.dart';
import 'package:forge_gym/core/analytics/analytics_service.dart';
import 'package:forge_gym/core/constants/app_info.dart';
import 'package:forge_gym/core/constants/backend_info.dart';
import 'package:forge_gym/core/errors/error_reporter.dart';
import 'package:forge_gym/core/firebase/firebase_bootstrap.dart';
import 'package:forge_gym/core/media/media_cache.dart';
import 'package:forge_gym/core/network/dio_client.dart';
import 'package:forge_gym/core/notifications/notification_service.dart';
import 'package:forge_gym/core/notifications/push_service.dart';
import 'package:forge_gym/features/auth/auth_dependencies.dart';
import 'package:forge_gym/features/challenges/challenges_dependencies.dart';
import 'package:forge_gym/features/exercises/exercises_dependencies.dart';
import 'package:forge_gym/features/home/home_dependencies.dart';
import 'package:forge_gym/features/profile/profile_dependencies.dart';
import 'package:forge_gym/features/progress/progress_dependencies.dart';
import 'package:forge_gym/features/workouts/workouts_dependencies.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service locator.
///
/// Read at composition roots (bootstrap, [GymApp], `BlocProvider` creation).
/// Domain and data classes receive their dependencies via constructors and
/// never touch this directly.
final GetIt getIt = GetIt.instance;

/// Registers the whole object graph. Called once from [bootstrap].
///
/// Order matters: platform storage first (async), then features in
/// dependency order (auth → exercises → workouts → progress → profile →
/// home), then navigation last since the router reads [AuthCubit].
Future<void> configureDependencies(EnvConfig config) async {
  final firebase = FirebaseBootstrap.isReady;

  // --- App -----------------------------------------------------------------
  getIt.registerSingleton<EnvConfig>(config);
  getIt.registerSingleton<BackendInfo>(
    BackendInfo(
      firebase: firebase,
      firebaseAuth: firebase && config.useFirebaseAuth,
    ),
  );
  getIt.registerSingleton<AppInfo>(await AppInfo.load());

  // --- Core ----------------------------------------------------------------
  getIt.registerLazySingleton<AnalyticsService>(DebugAnalyticsService.new);
  getIt.registerLazySingleton<ErrorReporter>(DebugErrorReporter.new);
  getIt.registerLazySingleton<Dio>(() => createDio(config));
  getIt.registerLazySingleton<NotificationService>(
    LocalNotificationService.new,
  );
  getIt.registerLazySingleton<PushService>(
    () => firebase
        ? FirebasePushService(
            FirebaseMessaging.instance,
            getIt<NotificationService>(),
          )
        : const NoopPushService(),
  );
  getIt.registerLazySingleton<MediaCache>(
    () => MediaCache(
      dio: createMediaDio(),
      baseUrl: config.mediaBaseUrl,
      urlResolver: firebase && config.usesFirebaseMedia
          ? (path) => FirebaseStorage.instance.ref(path).getDownloadURL()
          : null,
    ),
  );

  // --- Platform storage (async init, before features) ----------------------
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // --- Features ------------------------------------------------------------
  final firebaseAuth = firebase && config.useFirebaseAuth;
  await registerAuthDependencies(
    firebaseAuth: firebaseAuth ? fb.FirebaseAuth.instance : null,
  );
  await registerExercisesDependencies();
  await registerWorkoutsDependencies();
  await registerChallengesDependencies();
  await registerProgressDependencies();
  await registerProfileDependencies();
  await registerHomeDependencies();

  // --- Navigation ----------------------------------------------------------
  getIt.registerSingleton<AppRouter>(AppRouter());
}
