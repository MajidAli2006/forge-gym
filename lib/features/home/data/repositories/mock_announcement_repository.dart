import 'package:forge_gym/features/home/data/datasources/announcement_local_datasource.dart';
import 'package:forge_gym/features/home/domain/entities/announcement.dart';
import 'package:forge_gym/features/home/domain/repositories/announcement_repository.dart';

/// Announcement repository backed by bundled mock JSON. Satisfies the same
/// domain contract a future API implementation will.
class MockAnnouncementRepository implements AnnouncementRepository {
  MockAnnouncementRepository(this._dataSource);

  final AnnouncementLocalDataSource _dataSource;

  List<Announcement>? _cache;

  @override
  Future<List<Announcement>> getAnnouncements() async {
    if (_cache != null) return _cache!;
    // Simulate a short network round-trip so loading states are visible.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final dtos = await _dataSource.loadAnnouncements();
    _cache = dtos.map((dto) => dto.toDomain()).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return _cache!;
  }
}
