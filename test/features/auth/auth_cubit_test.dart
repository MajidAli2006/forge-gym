import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';
import 'package:forge_gym/features/auth/domain/repositories/auth_repository.dart';
import 'package:forge_gym/features/auth/domain/usecases/auth_usecases.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

AuthCubit buildCubit(MockAuthRepository repository) => AuthCubit(
  repository: repository,
  signInUseCase: SignInUseCase(repository),
  signUpUseCase: SignUpUseCase(repository),
  signOutUseCase: SignOutUseCase(repository),
  sendPasswordResetUseCase: SendPasswordResetUseCase(repository),
  updateProfileUseCase: UpdateProfileUseCase(repository),
  completeOnboardingUseCase: CompleteOnboardingUseCase(repository),
);

const user = User(
  id: 'mock-a@b.com',
  name: 'A B',
  email: 'a@b.com',
  fitnessLevel: FitnessLevel.intermediate,
);

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(
      () => repository.watchUser(),
    ).thenAnswer((_) => const Stream<User?>.empty());
  });

  group('AuthCubit.initialize', () {
    blocTest<AuthCubit, AuthState>(
      'emits [loading, unauthenticated] when there is no session',
      build: () => buildCubit(repository),
      setUp: () {
        when(
          () => repository.isOnboardingCompleted(),
        ).thenAnswer((_) async => false);
        when(() => repository.currentUser()).thenAnswer((_) async => null);
      },
      act: (cubit) => cubit.initialize(),
      wait: const Duration(seconds: 2),
      expect: () => const [
        AuthState.loading(),
        AuthState.unauthenticated(onboardingCompleted: false),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [loading, authenticated] when a session is restored',
      build: () => buildCubit(repository),
      setUp: () {
        when(
          () => repository.isOnboardingCompleted(),
        ).thenAnswer((_) async => true);
        when(() => repository.currentUser()).thenAnswer((_) async => user);
      },
      act: (cubit) => cubit.initialize(),
      wait: const Duration(seconds: 2),
      expect: () => [
        const AuthState.loading(),
        const AuthState.authenticated(user, onboardingCompleted: true),
      ],
    );

    test('second initialize() call is a no-op', () async {
      when(
        () => repository.isOnboardingCompleted(),
      ).thenAnswer((_) async => false);
      when(() => repository.currentUser()).thenAnswer((_) async => null);
      final cubit = buildCubit(repository);

      await cubit.initialize();
      await cubit.initialize();

      expect(cubit.state.status, AuthStatus.unauthenticated);
      verify(() => repository.currentUser()).called(1);
      await cubit.close();
    });
  });

  group('AuthCubit.signIn', () {
    blocTest<AuthCubit, AuthState>(
      'emits [loading, authenticated] on success',
      build: () => buildCubit(repository),
      setUp: () {
        when(
          () => repository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => user);
      },
      act: (cubit) => cubit.signIn(email: 'a@b.com', password: '123456'),
      expect: () => [
        const AuthState.loading(),
        const AuthState.authenticated(user, onboardingCompleted: false),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [loading, unauthenticated with error] on validation failure',
      build: () => buildCubit(repository),
      act: (cubit) => cubit.signIn(email: 'bad', password: '123456'),
      expect: () => [
        const AuthState.loading(),
        predicate<AuthState>(
          (s) =>
              s.status == AuthStatus.unauthenticated &&
              s.errorMessage != null &&
              s.user == null,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => repository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );
  });

  group('AuthCubit.signOut', () {
    blocTest<AuthCubit, AuthState>(
      'emits unauthenticated after sign out',
      build: () => buildCubit(repository),
      setUp: () {
        when(() => repository.signOut()).thenAnswer((_) async {});
      },
      seed: () =>
          const AuthState.authenticated(user, onboardingCompleted: true),
      act: (cubit) => cubit.signOut(),
      expect: () => const [
        AuthState.unauthenticated(onboardingCompleted: true),
      ],
    );
  });

  group('AuthCubit.sendPasswordReset', () {
    blocTest<AuthCubit, AuthState>(
      'emits loading then unauthenticated with passwordResetSent',
      build: () => buildCubit(repository),
      setUp: () {
        when(
          () => repository.sendPasswordReset(email: any(named: 'email')),
        ).thenAnswer((_) async {});
      },
      act: (cubit) => cubit.sendPasswordReset(email: 'a@b.com'),
      expect: () => const [
        AuthState.loading(),
        AuthState(status: AuthStatus.unauthenticated, passwordResetSent: true),
      ],
    );
  });

  group('AuthCubit.completeOnboarding', () {
    blocTest<AuthCubit, AuthState>(
      'flips onboardingCompleted without touching the session',
      build: () => buildCubit(repository),
      setUp: () {
        when(() => repository.completeOnboarding()).thenAnswer((_) async {});
      },
      seed: () => const AuthState.unauthenticated(onboardingCompleted: false),
      act: (cubit) => cubit.completeOnboarding(),
      expect: () => const [
        AuthState.unauthenticated(onboardingCompleted: true),
      ],
    );
  });
}
