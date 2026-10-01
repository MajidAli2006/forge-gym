import 'package:forge_gym/core/notifications/notification_service.dart';
import 'package:forge_gym/core/notifications/push_service.dart';
import 'package:forge_gym/features/profile/domain/entities/notification_preferences.dart';

/// Makes the device's scheduled reminder match the saved preference:
/// on → schedule daily at the chosen time; off → cancel.
///
/// With [prompt] the OS permission dialog may be shown (use from an
/// explicit member action such as flipping the toggle). Without it, the
/// reminder is only scheduled if permission was already granted — app
/// start must never open a system dialog on top of onboarding.
/// Returns false when notifications are not permitted.
class SyncWorkoutReminderUseCase {
  const SyncWorkoutReminderUseCase(
    this._notifications, {
    PushService push = const NoopPushService(),
  }) : _push = push;

  final NotificationService _notifications;
  final PushService _push;

  Future<bool> call(
    NotificationPreferences preferences, {
    bool prompt = true,
  }) async {
    // Announcements ride on push; the topic subscription mirrors the toggle.
    await _push.setAnnouncementsEnabled(
      preferences.announcements,
      prompt: prompt,
    );
    if (!preferences.workoutReminders) {
      await _notifications.cancelDailyReminder();
      return true;
    }
    final granted = prompt
        ? await _notifications.requestPermission()
        : await _notifications.hasPermission();
    if (!granted) {
      await _notifications.cancelDailyReminder();
      return false;
    }
    await _notifications.scheduleDailyReminder(
      hour: preferences.reminderHour,
      minute: preferences.reminderMinute,
    );
    return true;
  }
}
