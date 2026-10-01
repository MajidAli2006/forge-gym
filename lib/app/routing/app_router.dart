import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/app/routing/app_page.dart';
import 'package:forge_gym/app/routing/app_routes.dart';
import 'package:forge_gym/app/routing/scaffold_with_nav_bar.dart';
import 'package:forge_gym/features/auth/presentation/auth_route_paths.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_state.dart';
import 'package:forge_gym/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:forge_gym/features/auth/presentation/screens/login_screen.dart';
import 'package:forge_gym/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:forge_gym/features/auth/presentation/screens/register_screen.dart';
import 'package:forge_gym/features/auth/presentation/screens/splash_screen.dart';
import 'package:forge_gym/features/challenges/presentation/screens/challenges_screen.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercise_detail_cubit.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercises_cubit.dart';
import 'package:forge_gym/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:forge_gym/features/exercises/presentation/screens/exercises_screen.dart';
import 'package:forge_gym/features/exercises/presentation/screens/video_library_screen.dart';
import 'package:forge_gym/features/home/presentation/screens/home_screen.dart';
import 'package:forge_gym/features/profile/presentation/screens/profile_screen.dart';
import 'package:forge_gym/features/progress/presentation/screens/progress_screen.dart';
import 'package:forge_gym/features/workouts/domain/usecases/get_active_workout_usecase.dart';
import 'package:forge_gym/features/workouts/presentation/screens/active_workout_screen.dart';
import 'package:forge_gym/features/workouts/presentation/screens/routine_editor_screen.dart';
import 'package:forge_gym/features/workouts/presentation/screens/workout_detail_screen.dart';
import 'package:forge_gym/features/workouts/presentation/screens/workouts_screen.dart';
import 'package:go_router/go_router.dart';

/// Bridges a [Stream] (e.g. a cubit's) to the [Listenable] that
/// [GoRouter.refreshListenable] expects. go_router 18 no longer ships
/// `GoRouterRefreshStream`, so this tiny adapter replaces it.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Application router.
///
/// A [StatefulShellRoute.indexedStack] backs the bottom navigation: each tab
/// keeps its own navigation stack, so switching tabs never loses scroll
/// position or in-progress state.
///
/// Auth flow: the app starts at [/splash], which restores the session via
/// [AuthCubit]. Every [AuthCubit] emission re-runs [_authRedirect], which
/// steers to onboarding, login, or the tab shell. Auth screens are outside
/// the shell so the bottom bar never shows during sign-in.
class AppRouter {
  /// Root navigator: routes that pass it as `parentNavigatorKey` open
  /// above the tab shell, so focused tasks (a live workout, the routine
  /// editor) get the whole screen and the tab bar can't steal a tap.
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AuthRoutePaths.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: _StreamListenable(getIt<AuthCubit>().stream),
    redirect: _authRedirect,
    routes: <RouteBase>[
      GoRoute(
        path: AuthRoutePaths.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AuthRoutePaths.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) =>
            AppPage.fade(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: AuthRoutePaths.login,
        name: 'login',
        pageBuilder: (context, state) =>
            AppPage.fade(state, const LoginScreen()),
      ),
      GoRoute(
        path: AuthRoutePaths.register,
        name: 'register',
        pageBuilder: (context, state) =>
            AppPage.fade(state, const RegisterScreen()),
      ),
      GoRoute(
        path: AuthRoutePaths.forgotPassword,
        name: 'forgot-password',
        pageBuilder: (context, state) =>
            AppPage.fade(state, const ForgotPasswordScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'challenges',
                    name: 'challenges',
                    pageBuilder: (context, state) =>
                        AppPage.slideUp(state, const ChallengesScreen()),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.workouts,
                name: 'workouts',
                builder: (context, state) => const WorkoutsScreen(),
                routes: <RouteBase>[
                  // Static route first: must win over `:workoutId`.
                  GoRoute(
                    path: 'active/resume',
                    name: 'resume-workout',
                    redirect: (context, state) async {
                      final session = await getIt<GetActiveWorkoutUseCase>()();
                      final workoutId = session?.workoutId;
                      if (workoutId == null || workoutId.isEmpty) {
                        return AppRoutes.workouts;
                      }
                      return '${AppRoutes.workouts}/$workoutId/active';
                    },
                    builder: (context, state) => const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  GoRoute(
                    path: 'new',
                    name: 'new-routine',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => AppPage.slideUp(
                      state,
                      const RoutineEditorScreen(),
                    ),
                  ),
                  GoRoute(
                    path: ':workoutId',
                    name: 'workout-detail',
                    pageBuilder: (context, state) => AppPage.slideUp(
                      state,
                      WorkoutDetailScreen(
                        workoutId: state.pathParameters['workoutId']!,
                      ),
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'edit',
                        name: 'edit-routine',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (context, state) => AppPage.slideUp(
                          state,
                          RoutineEditorScreen(
                            routineId: state.pathParameters['workoutId'],
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'active',
                        name: 'active-workout',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (context, state) => AppPage.slideUp(
                          state,
                          ActiveWorkoutScreen(
                            workoutId: state.pathParameters['workoutId']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.exercises,
                name: 'exercises',
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<ExercisesCubit>(),
                  child: const ExercisesScreen(),
                ),
                routes: <RouteBase>[
                  // Static route first: must win over `:exerciseId`.
                  GoRoute(
                    path: 'videos',
                    name: 'video-library',
                    pageBuilder: (context, state) =>
                        AppPage.slideUp(state, const VideoLibraryScreen()),
                  ),
                  GoRoute(
                    path: ':exerciseId',
                    name: 'exercise-detail',
                    pageBuilder: (context, state) => AppPage.slideUp(
                      state,
                      BlocProvider(
                        create: (_) => getIt<ExerciseDetailCubit>(),
                        child: ExerciseDetailScreen(
                          exerciseId: state.pathParameters['exerciseId']!,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.progress,
                name: 'progress',
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  /// Auth gate. Runs on every navigation and on every [AuthCubit] emission.
  ///
  /// Returns the redirect target, or `null` to stay on the requested route.
  String? _authRedirect(BuildContext context, GoRouterState state) {
    final auth = getIt<AuthCubit>().state;
    final location = state.matchedLocation;

    const authRoutes = <String>{
      AuthRoutePaths.splash,
      AuthRoutePaths.onboarding,
      AuthRoutePaths.login,
      AuthRoutePaths.register,
      AuthRoutePaths.forgotPassword,
    };
    final onAuthRoute = authRoutes.contains(location);

    switch (auth.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        // Session restore in progress — hold on splash.
        return location == AuthRoutePaths.splash ? null : AuthRoutePaths.splash;
      case AuthStatus.authenticated:
        // Signed in: auth screens bounce back into the app.
        return onAuthRoute ? AppRoutes.home : null;
      case AuthStatus.unauthenticated:
        // First launch: onboarding before anything else.
        if (!auth.onboardingCompleted) {
          return location == AuthRoutePaths.onboarding
              ? null
              : AuthRoutePaths.onboarding;
        }
        // Splash and onboarding are finished: move on to login. Without
        // this, completing/skipping onboarding (or restoring a signed-out,
        // already-onboarded session on splash) would leave the member
        // stuck, because both paths are otherwise allowed auth routes.
        if (location == AuthRoutePaths.splash ||
            location == AuthRoutePaths.onboarding) {
          return AuthRoutePaths.login;
        }
        // Signed out: auth screens are fine, protected routes go to login.
        return onAuthRoute ? null : AuthRoutePaths.login;
    }
  }
}
