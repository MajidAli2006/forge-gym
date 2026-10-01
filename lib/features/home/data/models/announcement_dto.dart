import 'package:forge_gym/features/home/domain/entities/announcement.dart';

/// JSON shape of one announcement in `assets/mock/announcements.json`.
/// Never leaves the data layer.
class AnnouncementDto {
  const AnnouncementDto({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
  });

  factory AnnouncementDto.fromJson(Map<String, dynamic> json) {
    return AnnouncementDto(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  final String id;
  final String title;
  final String body;
  final DateTime date;

  Announcement toDomain() =>
      Announcement(id: id, title: title, body: body, date: date);
}
