import 'package:forge_gym/features/profile/domain/entities/notification_preferences.dart';

/// Contract for notification preference storage.
abstract class NotificationPreferencesRepository {
  Future<NotificationPreferences> get();
  Future<void> save(NotificationPreferences preferences);
}
