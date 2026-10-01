import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/app/app.dart';
import 'package:forge_gym/app/bootstrap/app_environment.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:forge_gym/features/challenges/data/datasources/challenge_local_datasource.dart';
import 'package:forge_gym/features/exercises/data/datasources/exercise_local_datasource.dart';
import 'package:forge_gym/features/home/data/datasources/announcement_local_datasource.dart';
import 'package:forge_gym/features/workouts/data/datasources/workout_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_doubles/fake_local_datasources.dart';

/// In-memory stand-in for flutter_secure_storage's platform channel, which
/// has no implementation under `flutter test`.
void _mockSecureStorage() {
  final store = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall call) async {
          final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
          final key = args['key'] as String?;
          switch (call.method) {
            case 'write':
              store[key!] = args['value'] as String;
            case 'read':
              return store[key];
            case 'delete':
              store.remove(key);
            case 'readAll':
              return Map<String, String>.from(store);
            case 'deleteAll':
              store.clear();
            case 'containsKey':
              return store.containsKey(key);
          }
          return null;
        },
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _mockSecureStorage();
    await getIt.reset();
    await configureDependencies(
      EnvConfig.forEnvironment(AppEnvironment.development),
    );
    // Widget tests run in flutter_tester, where rootBundle asset loading
    // never resolves. Swap the asset-backed data sources for in-memory
    // fakes (all registrations are lazy, so nothing has resolved yet).
    getIt.unregister<ExerciseLocalDataSource>();
    getIt.registerLazySingleton<ExerciseLocalDataSource>(
      FakeExerciseLocalDataSource.new,
    );
    getIt.unregister<WorkoutLocalDataSource>();
    getIt.registerLazySingleton<WorkoutLocalDataSource>(
      FakeWorkoutLocalDataSource.new,
    );
    getIt.unregister<AnnouncementLocalDataSource>();
    getIt.registerLazySingleton<AnnouncementLocalDataSource>(
      FakeAnnouncementLocalDataSource.new,
    );
    getIt.unregister<ChallengeLocalDataSource>();
    getIt.registerLazySingleton<ChallengeLocalDataSource>(
      FakeChallengeLocalDataSource.new,
    );
    // Drive the auth gate: onboarding done + signed in, so the router
    // lands on the tab shell instead of the auth screens.
    final auth = getIt<AuthCubit>();
    await auth.completeOnboarding();
    await auth.signIn(email: 'demo@forgegym.app', password: 'password123');
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('bottom navigation shows five tabs and switches screens', (
    tester,
  ) async {
    await tester.pumpWidget(const GymApp());
    await tester.pumpAndSettle();

    // All five destinations are present.
    expect(find.byType(NavigationDestination), findsNWidgets(5));

    // Switch to the Exercises tab and verify its screen appears.
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();

    expect(find.text('Push Up'), findsOneWidget);

    // Switch to the Profile tab and verify the signed-in user appears.
    await tester.tap(find.byType(NavigationDestination).at(4));
    await tester.pumpAndSettle();

    expect(find.text('Demo'), findsOneWidget);
  });
}
