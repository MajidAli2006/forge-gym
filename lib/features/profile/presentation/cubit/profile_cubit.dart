import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/core/errors/failures.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';
import 'package:forge_gym/features/auth/domain/repositories/auth_repository.dart';
import 'package:forge_gym/features/auth/domain/usecases/auth_usecases.dart';
import 'package:forge_gym/features/profile/domain/entities/notification_preferences.dart';
import 'package:forge_gym/features/profile/domain/repositories/notification_preferences_repository.dart';
import 'package:forge_gym/features/profile/domain/usecases/sync_workout_reminder_usecase.dart';
import 'package:forge_gym/features/profile/presentation/cubit/profile_state.dart';
import 'package:forge_gym/features/progress/domain/entities/weight_entry.dart';
import 'package:forge_gym/features/progress/domain/usecases/get_weight_history_usecase.dart';
import 'package:forge_gym/features/progress/domain/usecases/log_weight_usecase.dart';

/// Loads the signed-in member, persists profile edits through the auth
/// feature's [UpdateProfileUseCase], and stores notification preferences.
///
/// The cubit never talks to the auth feature's data layer — only its
/// domain contracts. It also follows [AuthRepository.watchUser] so edits
/// made elsewhere (e.g. logging a body weight on the progress tab) show
/// up here without a manual reload.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required AuthRepository authRepository,
    required UpdateProfileUseCase updateProfileUseCase,
    required NotificationPreferencesRepository preferencesRepository,
    required LogWeightUseCase logWeightUseCase,
    required GetWeightHistoryUseCase getWeightHistoryUseCase,
    required SyncWorkoutReminderUseCase syncWorkoutReminder,
  }) : _authRepository = authRepository,
       _updateProfileUseCase = updateProfileUseCase,
       _preferencesRepository = preferencesRepository,
       _logWeightUseCase = logWeightUseCase,
       _getWeightHistoryUseCase = getWeightHistoryUseCase,
       _syncWorkoutReminder = syncWorkoutReminder,
       super(const ProfileState());

  final AuthRepository _authRepository;
  final UpdateProfileUseCase _updateProfileUseCase;
  final NotificationPreferencesRepository _preferencesRepository;
  final LogWeightUseCase _logWeightUseCase;
  final GetWeightHistoryUseCase _getWeightHistoryUseCase;
  final SyncWorkoutReminderUseCase _syncWorkoutReminder;

  StreamSubscription<User?>? _userSubscription;

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final results = await Future.wait([
        _authRepository.currentUser(),
        _preferencesRepository.get(),
      ]);
      final user = await _withLatestWeight(results[0] as User?);
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          user: user,
          preferences: results[1]! as NotificationPreferences,
        ),
      );
      _userSubscription ??= _authRepository.watchUser().listen((user) {
        if (user != null && state.status != ProfileStatus.loading) {
          emit(state.copyWith(user: user));
        }
      });
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage:
              'Could not load your profile. Check your connection and try again.',
        ),
      );
    }
  }

  /// The progress tab is the source of truth for body weight. If the
  /// profile has no weight yet but weigh-ins exist, adopt the latest one
  /// (and persist it) so both screens always agree.
  Future<User?> _withLatestWeight(User? user) async {
    if (user == null || user.weightKg != null) return user;
    try {
      final history = await _getWeightHistoryUseCase();
      if (history.isEmpty) return user;
      return _updateProfileUseCase(
        user.copyWith(weightKg: history.first.weightKg),
      );
    } catch (_) {
      return user;
    }
  }

  /// Persists editable stats (age, height, weight) for the current user.
  /// A weight edit is also logged as today's body-weight entry so the
  /// progress chart stays in step with the profile.
  Future<void> updateStats({
    int? age,
    double? heightCm,
    double? weightKg,
  }) async {
    final user = state.user;
    if (user == null) return;
    emit(state.copyWith(status: ProfileStatus.saving));
    try {
      final updated = await _updateProfileUseCase(
        user.copyWith(age: age, heightCm: heightCm, weightKg: weightKg),
      );
      emit(state.copyWith(status: ProfileStatus.loaded, user: updated));
      if (weightKg != null && weightKg != user.weightKg) {
        await _logWeightUseCase(
          WeightEntry(date: DateTime.now(), weightKg: weightKg),
        );
      }
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          errorMessage: 'Could not save your changes. Please try again.',
        ),
      );
    }
  }

  Future<void> savePreferences(NotificationPreferences preferences) async {
    emit(
      state.copyWith(status: ProfileStatus.saving, preferences: preferences),
    );
    try {
      await _preferencesRepository.save(preferences);
      final granted = await _syncWorkoutReminder(preferences);
      if (!granted && preferences.workoutReminders) {
        // The OS refused: reflect reality instead of a toggle that lies.
        final reverted = preferences.copyWith(workoutReminders: false);
        await _preferencesRepository.save(reverted);
        emit(
          state.copyWith(
            status: ProfileStatus.loaded,
            preferences: reverted,
            errorMessage:
                'Notifications are blocked for Forge Gym. Allow them in your '
                'phone settings to get reminders.',
          ),
        );
        return;
      }
      emit(state.copyWith(status: ProfileStatus.loaded));
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          errorMessage: 'Could not save your preferences. Please try again.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
