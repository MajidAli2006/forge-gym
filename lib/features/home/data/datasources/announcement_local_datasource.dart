import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:forge_gym/features/home/data/models/announcement_dto.dart';

/// Loads announcement JSON. Abstract so tests can supply a fake.
abstract class AnnouncementLocalDataSource {
  Future<List<AnnouncementDto>> loadAnnouncements();
}

/// Reads the bundled mock file. Replaced by a remote data source later.
class AssetAnnouncementDataSource implements AnnouncementLocalDataSource {
  const AssetAnnouncementDataSource();

  @override
  Future<List<AnnouncementDto>> loadAnnouncements() async {
    final raw = await rootBundle.loadString('assets/mock/announcements.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => AnnouncementDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
