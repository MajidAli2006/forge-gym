import 'package:equatable/equatable.dart';

/// Aggregated training statistics computed from workout history.
///
/// Pure domain object — no Flutter.
class ProgressSummary extends Equatable {
  const ProgressSummary({
    required this.workoutsThisWeek,
    required this.currentStreakDays,
    required this.totalWorkouts,
    required this.totalMinutes,
    required this.totalVolumeKg,
  });

  /// Finished workouts since Monday of the current week.
  final int workoutsThisWeek;

  /// Consecutive days with at least one workout, ending today or yesterday.
  final int currentStreakDays;

  final int totalWorkouts;
  final int totalMinutes;
  final double totalVolumeKg;

  @override
  List<Object?> get props => [
    workoutsThisWeek,
    currentStreakDays,
    totalWorkouts,
    totalMinutes,
    totalVolumeKg,
  ];
}
