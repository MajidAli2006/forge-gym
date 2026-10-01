import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/core/errors/failures.dart';
import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';
import 'package:forge_gym/features/auth/domain/repositories/auth_repository.dart';
import 'package:forge_gym/features/auth/domain/usecases/auth_usecases.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_state.dart';

/// Owns the session for the app: splash initialization, sign in/up/out,
/// password reset, onboarding completion, and profile updates.
///
/// The [GoRouter] auth gate listens to this cubit's stream, so every
/// state change re-evaluates redirects.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository repository,
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required SendPasswordResetUseCase sendPasswordResetUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required CompleteOnboardingUseCase completeOnboardingUseCase,
  }) : _repository = repository,
       _signInUseCase = signInUseCase,
       _signUpUseCase = signUpUseCase,
       _signOutUseCase = signOutUseCase,
       _sendPasswordResetUseCase = sendPasswordResetUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _completeOnboardingUseCase = completeOnboardingUseCase,
       super(const AuthState.initial());

  final AuthRepository _repository;
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final SendPasswordResetUseCase _sendPasswordResetUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final CompleteOnboardingUseCase _completeOnboardingUseCase;

  StreamSubscription<User?>? _userSubscription;
  bool _initialized = false;

  /// Restores the session and onboarding flag. Called once from the splash
  /// screen. Keeps a minimum display time so the splash doesn't flash.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    emit(const AuthState.loading());
    final stopwatch = Stopwatch()..start();
    try {
      final results = await Future.wait([
        _repository.isOnboardingCompleted(),
        _repository.currentUser(),
      ]);
      final onboardingCompleted = results[0]! as bool;
      final user = results[1] as User?;
      _userSubscription = _repository.watchUser().listen(_onUserChanged);
      final elapsed = stopwatch.elapsed;
      if (elapsed < const Duration(milliseconds: 800)) {
        await Future<void>.delayed(const Duration(milliseconds: 800) - elapsed);
      }
      if (user != null) {
        emit(
          AuthState.authenticated(
            user,
            onboardingCompleted: onboardingCompleted,
          ),
        );
      } else {
        emit(
          AuthState.unauthenticated(onboardingCompleted: onboardingCompleted),
        );
      }
    } catch (error) {
      emit(
        const AuthState.unauthenticated(
          onboardingCompleted: false,
        ).copyWith(errorMessage: _messageFor(error)),
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final user = await _signInUseCase(email: email, password: password);
      emit(
        AuthState.authenticated(
          user,
          onboardingCompleted: state.onboardingCompleted,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required FitnessLevel fitnessLevel,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final user = await _signUpUseCase(
        name: name,
        email: email,
        password: password,
        fitnessLevel: fitnessLevel,
      );
      emit(
        AuthState.authenticated(
          user,
          onboardingCompleted: state.onboardingCompleted,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _signOutUseCase();
    } catch (error) {
      emit(state.copyWith(errorMessage: _messageFor(error)));
      return;
    }
    emit(
      AuthState.unauthenticated(onboardingCompleted: state.onboardingCompleted),
    );
  }

  Future<void> sendPasswordReset({required String email}) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        passwordResetSent: false,
      ),
    );
    try {
      await _sendPasswordResetUseCase(email: email);
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          passwordResetSent: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  Future<void> updateProfile(User user) async {
    final wasAuthenticated = state.isAuthenticated;
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final updated = await _updateProfileUseCase(user);
      emit(
        AuthState.authenticated(
          updated,
          onboardingCompleted: state.onboardingCompleted,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: wasAuthenticated
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  Future<void> completeOnboarding() async {
    try {
      await _completeOnboardingUseCase();
      emit(state.copyWith(onboardingCompleted: true, clearError: true));
    } catch (error) {
      emit(state.copyWith(errorMessage: _messageFor(error)));
    }
  }

  void clearError() => emit(state.copyWith(clearError: true));

  void _onUserChanged(User? user) {
    if (user == null) {
      if (state.isAuthenticated) {
        emit(
          AuthState.unauthenticated(
            onboardingCompleted: state.onboardingCompleted,
          ),
        );
      }
    } else if (!state.isAuthenticated || state.user != user) {
      emit(
        AuthState.authenticated(
          user,
          onboardingCompleted: state.onboardingCompleted,
        ),
      );
    }
  }

  String _messageFor(Object error) => error is Failure
      ? error.message
      : 'Something unexpected happened. Please try again.';

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
