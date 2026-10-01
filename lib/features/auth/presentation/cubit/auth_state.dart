import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';

/// High-level session status derived from [AuthState].
enum AuthStatus { initial, loading, authenticated, unauthenticated }

/// Immutable UI state for the whole auth feature.
///
/// A single cubit owns the session (rather than per-screen cubits) because
/// the router's auth gate also reads this state.
class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.onboardingCompleted = false,
    this.passwordResetSent = false,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool onboardingCompleted;
  final bool passwordResetSent;

  const AuthState.initial() : this(status: AuthStatus.initial);

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated(User user, {required bool onboardingCompleted})
    : this(
        status: AuthStatus.authenticated,
        user: user,
        onboardingCompleted: onboardingCompleted,
      );

  const AuthState.unauthenticated({required bool onboardingCompleted})
    : this(
        status: AuthStatus.unauthenticated,
        onboardingCompleted: onboardingCompleted,
      );

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? onboardingCompleted,
    bool? passwordResetSent,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      passwordResetSent: passwordResetSent ?? this.passwordResetSent,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    errorMessage,
    onboardingCompleted,
    passwordResetSent,
  ];
}
