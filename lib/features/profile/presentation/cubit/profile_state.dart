import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';
import 'package:forge_gym/features/profile/domain/entities/notification_preferences.dart';

/// Lifecycle of the profile screen data load.
enum ProfileStatus { initial, loading, loaded, saving, error }

/// Everything the profile screen renders.
class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.preferences = const NotificationPreferences(),
    this.errorMessage,
  });

  final ProfileStatus status;
  final User? user;
  final NotificationPreferences preferences;
  final String? errorMessage;

  ProfileState copyWith({
    ProfileStatus? status,
    User? user,
    NotificationPreferences? preferences,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      preferences: preferences ?? this.preferences,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, preferences, errorMessage];
}
