import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/core/errors/failures.dart';
import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';
import 'package:forge_gym/features/auth/domain/repositories/auth_repository.dart';
import 'package:forge_gym/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(FitnessLevel.beginner);
  });

  late MockAuthRepository repository;
  late SignInUseCase signIn;
  late SignUpUseCase signUp;
  late SendPasswordResetUseCase sendReset;

  const user = User(
    id: 'mock-a@b.com',
    name: 'A B',
    email: 'a@b.com',
    fitnessLevel: FitnessLevel.beginner,
  );

  setUp(() {
    repository = MockAuthRepository();
    signIn = SignInUseCase(repository);
    signUp = SignUpUseCase(repository);
    sendReset = SendPasswordResetUseCase(repository);
  });

  group('SignInUseCase', () {
    test('delegates to the repository with trimmed email', () async {
      when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => user);

      final result = await signIn(email: '  a@b.com ', password: '123456');

      expect(result, user);
      verify(
        () => repository.signIn(email: 'a@b.com', password: '123456'),
      ).called(1);
    });

    test(
      'throws ValidationFailure for a bad email without calling repo',
      () async {
        expect(
          () => signIn(email: 'nope', password: '123456'),
          throwsA(isA<ValidationFailure>()),
        );
        verifyNever(
          () => repository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    test('throws ValidationFailure for a short password', () async {
      expect(
        () => signIn(email: 'a@b.com', password: '123'),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('SignUpUseCase', () {
    test('throws ValidationFailure for a blank name', () async {
      expect(
        () => signUp(
          name: ' ',
          email: 'a@b.com',
          password: '123456',
          fitnessLevel: FitnessLevel.beginner,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      verifyNever(
        () => repository.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          fitnessLevel: any(named: 'fitnessLevel'),
        ),
      );
    });
  });

  group('SendPasswordResetUseCase', () {
    test('throws ValidationFailure for a bad email', () async {
      expect(() => sendReset(email: 'bad'), throwsA(isA<ValidationFailure>()));
      verifyNever(
        () => repository.sendPasswordReset(email: any(named: 'email')),
      );
    });
  });
}
