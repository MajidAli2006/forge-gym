/// Display formatters shared across features. Pure Dart — no Flutter,
/// no locale packages — so they are trivially unit-testable.
abstract final class Formatters {
  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// `30 Sep 2026`
  static String date(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  /// `Sep`
  static String monthShort(DateTime date) => _months[date.month - 1];

  /// `Wed`
  static String weekdayShort(DateTime date) => _weekdays[date.weekday - 1];

  /// `Today`, `Yesterday`, or `30 Sep 2026`.
  static String relativeDate(DateTime date, {DateTime? now}) {
    final today = _dayOf(now ?? DateTime.now());
    final day = _dayOf(date);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return Formatters.date(date);
  }

  /// `82`, `82.5` — drops a trailing `.0`.
  static String number(double value, {int decimals = 1}) => value % 1 == 0
      ? value.toInt().toString()
      : value.toStringAsFixed(decimals);

  /// `82.5 kg`
  static String kg(double value) => '${number(value)} kg';

  /// `1,250` — thousands separators, no decimals.
  static String grouped(num value) {
    final digits = value.round().abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// `45 min`, `1h 20m`
  static String durationMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }

  /// `45 min` from seconds (rounds up so a 20 s workout reads `1 min`).
  static String durationSeconds(int seconds) =>
      durationMinutes(seconds <= 0 ? 0 : ((seconds + 59) ~/ 60));

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
}
