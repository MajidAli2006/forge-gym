import 'package:forge_gym/core/errors/failures.dart';
import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';
import 'package:forge_gym/features/auth/domain/repositories/auth_repository.dart';
import 'package:forge_gym/features/auth/domain/validators/auth_rules.dart';

/// Signs a member in with email + password.
class SignInUseCase {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call({required String email, required String password}) {
    final emailError = AuthRules.validateEmail(email);
    if (emailError != null) throw ValidationFailure(emailError);
    final passwordError = AuthRules.validatePassword(password);
    if (passwordError != null) throw ValidationFailure(passwordError);
    return _repository.signIn(email: email.trim(), password: password);
  }
}

/// Registers a new member.
class SignUpUseCase {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call({
    required String name,
    required String email,
    required String password,
    required FitnessLevel fitnessLevel,
  }) {
    final nameError = AuthRules.validateName(name);
    if (nameError != null) throw ValidationFailure(nameError);
    final emailError = AuthRules.validateEmail(email);
    if (emailError != null) throw ValidationFailure(emailError);
    final passwordError = AuthRules.validatePassword(password);
    if (passwordError != null) throw ValidationFailure(passwordError);
    return _repository.signUp(
      name: name.trim(),
      email: email.trim(),
      password: password,
      fitnessLevel: fitnessLevel,
    );
  }
}

/// Signs the current member out, clearing the stored session.
class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}

/// Sends a password-reset email (mock: always succeeds for a valid email).
class SendPasswordResetUseCase {
  const SendPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email}) {
    final emailError = AuthRules.validateEmail(email);
    if (emailError != null) throw ValidationFailure(emailError);
    return _repository.sendPasswordReset(email: email.trim());
  }
}

/// Persists profile edits for the signed-in member.
class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call(User user) {
    final nameError = AuthRules.validateName(user.name);
    if (nameError != null) throw ValidationFailure(nameError);
    return _repository.updateProfile(user);
  }
}

/// Marks first-run onboarding as completed.
class CompleteOnboardingUseCase {
  const CompleteOnboardingUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.completeOnboarding();
}
