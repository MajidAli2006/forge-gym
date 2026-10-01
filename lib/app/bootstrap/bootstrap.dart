import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forge_gym/app/app.dart';
import 'package:forge_gym/app/bootstrap/app_environment.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/core/errors/error_reporter.dart';
import 'package:forge_gym/core/firebase/firebase_bootstrap.dart';
import 'package:forge_gym/core/notifications/notification_service.dart';
import 'package:forge_gym/core/notifications/push_service.dart';
import 'package:forge_gym/features/profile/domain/repositories/notification_preferences_repository.dart';
import 'package:forge_gym/features/profile/domain/usecases/sync_workout_reminder_usecase.dart';

/// Single bootstrap for every flavor.
///
/// Order matters: widget binding → environment config → dependencies →
/// error hooks → runApp.
Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = EnvConfig.forEnvironment(environment);
  // Firebase must be up before DI decides between Firebase-backed and
  // local implementations. Best-effort: the app runs without it.
  await FirebaseBootstrap.initialize();
  await configureDependencies(config);

  final errorReporter = getIt<ErrorReporter>();

  // Local notifications: initialise the plugin and make sure the daily
  // reminder matches the saved preference (best-effort, never blocks start).
  await getIt<NotificationService>().initialize();
  await getIt<PushService>().initialize();
  unawaited(_syncReminder());

  FlutterError.onError = (details) {
    errorReporter.recordError(
      details.exception,
      details.stack ?? StackTrace.empty,
      reason: 'FlutterError',
    );
    if (config.isDevelopment) {
      FlutterError.presentError(details);
    }
  };

  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    errorReporter.recordError(
      error,
      stack,
      reason: 'PlatformDispatcher',
      fatal: true,
    );
    return true;
  };

  // Uncaught async errors are routed through [PlatformDispatcher.onError]
  // above. Wrapping runApp in runZonedGuarded here would run it in a
  // different zone than ensureInitialized() and trigger Flutter's
  // "Zone mismatch" assertion on startup.
  runApp(const GymApp());
}

Future<void> _syncReminder() async {
  try {
    final preferences = await getIt<NotificationPreferencesRepository>().get();
    await getIt<SyncWorkoutReminderUseCase>()(preferences, prompt: false);
  } catch (_) {
    // A failed sync only means no reminder today; the profile screen
    // re-syncs on the next change.
  }
}
