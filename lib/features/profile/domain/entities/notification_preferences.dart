import 'package:equatable/equatable.dart';

/// Member's notification preferences. Pure domain object — no Flutter.
///
/// Push delivery itself arrives with the backend/FCM update; these flags
/// decide what the app may send once that exists.
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.workoutReminders = true,
    this.announcements = true,
    this.reminderHour = 18,
    this.reminderMinute = 0,
  });

  /// Daily local reminder, scheduled on the device.
  final bool workoutReminders;

  /// Push announcements — delivered once the backend push service exists.
  final bool announcements;

  /// Local wall-clock time of the daily reminder.
  final int reminderHour;
  final int reminderMinute;

  NotificationPreferences copyWith({
    bool? workoutReminders,
    bool? announcements,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return NotificationPreferences(
      workoutReminders: workoutReminders ?? this.workoutReminders,
      announcements: announcements ?? this.announcements,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  @override
  List<Object?> get props => [
    workoutReminders,
    announcements,
    reminderHour,
    reminderMinute,
  ];
}
