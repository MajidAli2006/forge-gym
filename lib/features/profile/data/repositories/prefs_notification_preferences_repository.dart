import 'dart:convert';

import 'package:forge_gym/features/profile/domain/entities/notification_preferences.dart';
import 'package:forge_gym/features/profile/domain/repositories/notification_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification preferences in [SharedPreferences] (non-sensitive).
class PrefsNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  PrefsNotificationPreferencesRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'forge.notification_prefs';

  @override
  Future<NotificationPreferences> get() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const NotificationPreferences();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return NotificationPreferences(
      workoutReminders: json['workoutReminders'] as bool? ?? true,
      announcements: json['announcements'] as bool? ?? true,
      reminderHour: (json['reminderHour'] as num?)?.toInt() ?? 18,
      reminderMinute: (json['reminderMinute'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> save(NotificationPreferences preferences) async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'workoutReminders': preferences.workoutReminders,
        'announcements': preferences.announcements,
        'reminderHour': preferences.reminderHour,
        'reminderMinute': preferences.reminderMinute,
      }),
    );
  }
}
