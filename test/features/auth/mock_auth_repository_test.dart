import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';

import 'test_helpers.dart';

void main() {
  late FakeAuthLocalDataSource local;
  late MockAuthRepository repository;

  setUp(() {
    local = FakeAuthLocalDataSource();
    repository = MockAuthRepository(local);
  });

  group('MockAuthRepository', () {
    test('signIn accepts valid credentials and persists the session', () async {
      final user = await repository.signIn(
        email: 'demo@forgegym.app',
        password: 'password123',
      );

      expect(user.email, 'demo@forgegym.app');
      expect(user.name, 'Demo'); // derived from email prefix
      expect(local.token, startsWith('mock-token-'));
      expect(local.userJson, contains('demo@forgegym.app'));
      expect(await repository.currentUser(), equals(user));
    });

    test('signIn uses the name saved at sign-up', () async {
      await repository.signUp(
        name: 'Alex Morgan',
        email: 'alex@example.com',
        password: 'password123',
        fitnessLevel: FitnessLevel.intermediate,
      );
      await repository.signOut();

      final user = await repository.signIn(
        email: 'alex@example.com',
        password: 'password123',
      );
      expect(user.name, 'Alex Morgan');
    });

    test('signUp stores the name and fitness level', () async {
      final user = await repository.signUp(
        name: 'Sam Lee',
        email: 'sam@example.com',
        password: 'password123',
        fitnessLevel: FitnessLevel.advanced,
      );

      expect(user.name, 'Sam Lee');
      expect(user.fitnessLevel, FitnessLevel.advanced);
      expect(local.profileNames['sam@example.com'], 'Sam Lee');
    });

    test('signOut clears the session', () async {
      await repository.signIn(email: 'a@b.com', password: '123456');
      await repository.signOut();

      expect(local.token, isNull);
      expect(await repository.currentUser(), isNull);
    });

    test('watchUser emits the restored session on listen', () async {
      await repository.signIn(email: 'a@b.com', password: '123456');

      // Fresh repository over the same storage simulates an app restart.
      final restarted = MockAuthRepository(local);
      final first = await restarted.watchUser().first;
      expect(first?.email, 'a@b.com');
    });

    test('watchUser emits null after signOut', () async {
      await repository.signIn(email: 'a@b.com', password: '123456');
      final emissions = <Object?>[];
      final sub = repository.watchUser().listen(emissions.add);
      await repository.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(emissions.last, isNull);
    });

    test('updateProfile persists and re-emits the user', () async {
      final user = await repository.signIn(
        email: 'a@b.com',
        password: '123456',
      );
      final updated = await repository.updateProfile(
        user.copyWith(name: 'New Name', age: 33),
      );

      expect(updated.name, 'New Name');
      expect(updated.age, 33);
      expect(local.userJson, contains('New Name'));
    });

    test('onboarding flag round-trips', () async {
      expect(await repository.isOnboardingCompleted(), isFalse);
      await repository.completeOnboarding();
      expect(await repository.isOnboardingCompleted(), isTrue);
    });

    test('sendPasswordReset succeeds without throwing', () async {
      await repository.sendPasswordReset(email: 'a@b.com');
    });
  });
}
