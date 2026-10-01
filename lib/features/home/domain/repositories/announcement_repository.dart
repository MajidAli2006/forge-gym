import 'package:forge_gym/features/home/domain/entities/announcement.dart';

/// Contract for gym announcements. Mock JSON today, API later.
abstract class AnnouncementRepository {
  /// Announcements, newest first.
  Future<List<Announcement>> getAnnouncements();
}
