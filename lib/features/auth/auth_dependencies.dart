import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:forge_gym/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:forge_gym/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:forge_gym/features/auth/domain/repositories/auth_repository.dart';
import 'package:forge_gym/features/auth/domain/usecases/auth_usecases.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registers the auth object graph.
///
/// Expects [FlutterSecureStorage] and [SharedPreferences] to already be
/// registered (bootstrap registers them — they need async initialization).
/// The router reads the same [AuthCubit] singleton instance, so it must be
/// a singleton, not a factory.
///
/// Pass [firebaseAuth] to back accounts with Firebase Authentication;
/// without it the local mock (any email + 6-char password) is used.
Future<void> registerAuthDependencies({fb.FirebaseAuth? firebaseAuth}) async {
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      getIt<FlutterSecureStorage>(),
      getIt<SharedPreferences>(),
    ),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => firebaseAuth != null
        ? FirebaseAuthRepository(firebaseAuth, getIt<AuthLocalDataSource>())
        : MockAuthRepository(getIt<AuthLocalDataSource>()),
  );

  getIt.registerLazySingleton<SignInUseCase>(
    () => SignInUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignUpUseCase>(
    () => SignUpUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignOutUseCase>(
    () => SignOutUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SendPasswordResetUseCase>(
    () => SendPasswordResetUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<UpdateProfileUseCase>(
    () => UpdateProfileUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<CompleteOnboardingUseCase>(
    () => CompleteOnboardingUseCase(getIt<AuthRepository>()),
  );

  getIt.registerSingleton<AuthCubit>(
    AuthCubit(
      repository: getIt<AuthRepository>(),
      signInUseCase: getIt<SignInUseCase>(),
      signUpUseCase: getIt<SignUpUseCase>(),
      signOutUseCase: getIt<SignOutUseCase>(),
      sendPasswordResetUseCase: getIt<SendPasswordResetUseCase>(),
      updateProfileUseCase: getIt<UpdateProfileUseCase>(),
      completeOnboardingUseCase: getIt<CompleteOnboardingUseCase>(),
    ),
  );
}
