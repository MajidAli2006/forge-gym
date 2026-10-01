import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';

/// Contract for authentication.
///
/// Implemented by [MockAuthRepository] today and by a future
/// `ApiAuthRepository` without any presentation changes. Failures surface as
/// [Failure] subtypes (e.g. [ValidationFailure], [UnauthorizedFailure]) —
/// never raw exceptions.
abstract class AuthRepository {
  /// Emits the current user whenever the session changes (sign in/out,
  /// profile update). Emits the restored session on first listen.
  Stream<User?> watchUser();

  /// The currently signed-in user, or null when there is no session.
  Future<User?> currentUser();

  Future<User> signIn({required String email, required String password});

  Future<User> signUp({
    required String name,
    required String email,
    required String password,
    required FitnessLevel fitnessLevel,
  });

  Future<void> signOut();

  Future<void> sendPasswordReset({required String email});

  /// Persists profile edits (name, age, height, weight, fitness level…).
  Future<User> updateProfile(User user);

  Future<bool> isOnboardingCompleted();

  Future<void> completeOnboarding();
}
