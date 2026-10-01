import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local (on-device) notifications. No backend is involved: the phone
/// schedules them itself, so they work offline and survive reboots.
///
/// Two use cases today:
/// - a daily workout reminder at the member's chosen time;
/// - "rest over" when a rest countdown ends while the app is in the
///   background or the screen is off.
///
/// Gym-wide announcements need a push service (e.g. FCM) and are out of
/// scope for this class.
abstract class NotificationService {
  Future<void> initialize();

  /// Whether the OS currently allows this app to post notifications.
  Future<bool> hasPermission();

  /// Asks the OS for permission (Android 13+). Returns whether granted.
  Future<bool> requestPermission();

  Future<void> scheduleDailyReminder({required int hour, required int minute});
  Future<void> cancelDailyReminder();

  Future<void> scheduleRestFinished({
    required Duration after,
    required String upNext,
  });
  Future<void> cancelRestFinished();

  /// Shows a notification immediately (used for push messages that arrive
  /// while the app is in the foreground).
  Future<void> showNow({required String title, required String body});
}

/// Used in tests and as the default for cubits: never touches a platform
/// channel.
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {}
  @override
  Future<void> cancelDailyReminder() async {}
  @override
  Future<void> scheduleRestFinished({
    required Duration after,
    required String upNext,
  }) async {}
  @override
  Future<void> cancelRestFinished() async {}
  @override
  Future<void> showNow({required String title, required String body}) async {}
}

/// Production implementation on `flutter_local_notifications`.
///
/// Every call is best-effort: a missing plugin (widget tests) or a denied
/// permission must never break a workout, so failures are logged and
/// swallowed.
class LocalNotificationService implements NotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const int _reminderId = 1001;
  static const int _restId = 2001;
  static const int _pushBaseId = 3000;
  int _pushCounter = 0;

  static const AndroidNotificationDetails _announcementDetails =
      AndroidNotificationDetails(
        'announcements',
        'Gym announcements',
        channelDescription: 'News, classes and schedule changes from the gym.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

  static const AndroidNotificationDetails _reminderDetails =
      AndroidNotificationDetails(
        'workout_reminders',
        'Workout reminders',
        channelDescription: 'A daily nudge at the time you choose.',
        importance: Importance.high,
        priority: Priority.high,
      );

  static const AndroidNotificationDetails _restDetails =
      AndroidNotificationDetails(
        'active_workout',
        'Active workout',
        channelDescription: 'Rest timer finished while the app was closed.',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
      );

  @override
  Future<void> initialize() async {
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (error) {
      debugPrint('[Notifications] initialize failed: $error');
    }
  }

  @override
  Future<bool> hasPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? true;
    } catch (error) {
      debugPrint('[Notifications] permission check failed: $error');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? true;
    } catch (error) {
      debugPrint('[Notifications] permission request failed: $error');
      return false;
    }
  }

  /// The plugin needs a zoned time; the app has no timezone database for
  /// the device, so schedule in UTC derived from the local wall-clock time.
  static tz.TZDateTime _utc(DateTime local) {
    final utc = local.toUtc();
    return tz.TZDateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    );
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_ready) return;
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await _schedule(
      id: _reminderId,
      at: next,
      title: 'Time to train',
      body: 'Your workout reminder. Even a short session keeps the streak.',
      details: _reminderDetails,
      repeatDaily: true,
    );
  }

  @override
  Future<void> cancelDailyReminder() => _cancel(_reminderId);

  @override
  Future<void> scheduleRestFinished({
    required Duration after,
    required String upNext,
  }) async {
    if (!_ready || after <= Duration.zero) return;
    await _schedule(
      id: _restId,
      at: DateTime.now().add(after),
      title: 'Rest over — back to it',
      body: upNext,
      details: _restDetails,
      repeatDaily: false,
    );
  }

  @override
  Future<void> cancelRestFinished() => _cancel(_restId);

  @override
  Future<void> showNow({required String title, required String body}) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: _pushBaseId + (_pushCounter++ % 100),
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: _announcementDetails,
        ),
      );
    } catch (error) {
      debugPrint('[Notifications] show failed: $error');
    }
  }

  Future<void> _schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required AndroidNotificationDetails details,
    required bool repeatDaily,
  }) async {
    final notificationDetails = NotificationDetails(android: details);
    final scheduledDate = _utc(at);
    final components = repeatDaily ? DateTimeComponents.time : null;
    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: title,
        body: body,
        matchDateTimeComponents: components,
      );
    } catch (error) {
      // Exact alarms can be refused on some devices; fall back to inexact
      // delivery rather than dropping the notification entirely.
      debugPrint('[Notifications] exact schedule failed: $error');
      try {
        await _plugin.zonedSchedule(
          id: id,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: title,
          body: body,
          matchDateTimeComponents: components,
        );
      } catch (fallbackError) {
        debugPrint('[Notifications] schedule failed: $fallbackError');
      }
    }
  }

  Future<void> _cancel(int id) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (error) {
      debugPrint('[Notifications] cancel failed: $error');
    }
  }
}
