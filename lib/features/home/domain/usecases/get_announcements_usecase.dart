import 'package:forge_gym/features/home/domain/entities/announcement.dart';
import 'package:forge_gym/features/home/domain/repositories/announcement_repository.dart';

/// Loads gym announcements for the home dashboard.
class GetAnnouncementsUseCase {
  const GetAnnouncementsUseCase(this._repository);

  final AnnouncementRepository _repository;

  Future<List<Announcement>> call() => _repository.getAnnouncements();
}
