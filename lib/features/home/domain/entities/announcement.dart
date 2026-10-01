import 'package:equatable/equatable.dart';

/// A message from the gym (new classes, maintenance, holiday hours…).
///
/// Pure domain object — no JSON, no Flutter.
class Announcement extends Equatable {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
  });

  final String id;
  final String title;
  final String body;
  final DateTime date;

  @override
  List<Object?> get props => [id, title, body, date];
}
