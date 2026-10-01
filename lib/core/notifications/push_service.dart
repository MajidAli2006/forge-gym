import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:forge_gym/core/notifications/notification_service.dart';

/// Gym-wide push notifications (announcements) through Firebase Cloud
/// Messaging.
///
/// Members who keep "Gym announcements" on are subscribed to the
/// `announcements` topic; the gym sends to that topic from the Firebase
/// console (Messaging → New campaign → Topic). Messages that arrive while
/// the app is open are shown through [NotificationService] so they look
/// like every other notification; in the background the OS shows them.
abstract class PushService {
  bool get isAvailable;
  Future<void> initialize();

  /// Subscribes to / unsubscribes from the announcements topic. With
  /// [prompt] the OS permission dialog may be shown; without it the
  /// subscription is only made when permission was already granted.
  Future<void> setAnnouncementsEnabled(bool enabled, {bool prompt = true});
}

class NoopPushService implements PushService {
  const NoopPushService();

  @override
  bool get isAvailable => false;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> setAnnouncementsEnabled(
    bool enabled, {
    bool prompt = true,
  }) async {}
}

class FirebasePushService implements PushService {
  FirebasePushService(this._messaging, this._local);

  static const String announcementsTopic = 'announcements';

  final FirebaseMessaging _messaging;
  final NotificationService _local;
  StreamSubscription<RemoteMessage>? _foreground;
  bool _ready = false;

  @override
  bool get isAvailable => _ready;

  @override
  Future<void> initialize() async {
    try {
      // Foreground messages: FCM does not display these itself.
      _foreground = FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification == null) return;
        unawaited(
          _local.showNow(
            title: notification.title ?? 'Forge Gym',
            body: notification.body ?? '',
          ),
        );
      });
      _ready = true;
    } catch (error) {
      debugPrint('[Push] initialize failed: $error');
      _ready = false;
    }
  }

  @override
  Future<void> setAnnouncementsEnabled(
    bool enabled, {
    bool prompt = true,
  }) async {
    if (!_ready) return;
    try {
      if (enabled) {
        final settings = prompt
            ? await _messaging.requestPermission()
            : await _messaging.getNotificationSettings();
        if (settings.authorizationStatus != AuthorizationStatus.authorized &&
            settings.authorizationStatus != AuthorizationStatus.provisional) {
          return;
        }
        await _messaging.subscribeToTopic(announcementsTopic);
      } else {
        await _messaging.unsubscribeFromTopic(announcementsTopic);
      }
    } catch (error) {
      debugPrint('[Push] topic update failed: $error');
    }
  }

  void dispose() {
    _foreground?.cancel();
  }
}
