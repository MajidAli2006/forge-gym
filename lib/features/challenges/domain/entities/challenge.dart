import 'package:equatable/equatable.dart';
import 'package:forge_gym/core/utils/formatters.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

/// What a challenge measures. Every metric is derived from finished
/// workouts, so members never enter anything by hand.
enum ChallengeMetric {
  /// Finished workouts.
  workouts,

  /// Consecutive training days.
  streakDays,

  /// Minutes of finished workouts.
  minutes,

  /// Total load lifted (reps × kg over weighted sets).
  volumeKg,

  /// Reps of one exercise (needs [Challenge.exerciseId]).
  exerciseReps,

  /// Seconds held for one timed exercise (needs [Challenge.exerciseId]).
  holdSeconds,
}

extension ChallengeMetricFormat on ChallengeMetric {
  /// `12 workouts`, `10,000 kg`, `10 min`.
  String format(int value) => switch (this) {
    ChallengeMetric.workouts => value == 1 ? '1 workout' : '$value workouts',
    ChallengeMetric.streakDays => value == 1 ? '1 day' : '$value days',
    ChallengeMetric.minutes => '${Formatters.grouped(value)} min',
    ChallengeMetric.volumeKg => '${Formatters.grouped(value)} kg',
    ChallengeMetric.exerciseReps => '${Formatters.grouped(value)} reps',
    ChallengeMetric.holdSeconds =>
      value >= 60 ? '${value ~/ 60} min ${value % 60}s' : '${value}s',
  };

  /// Short unit for compact "current / target" strings.
  String unit(int value) => switch (this) {
    ChallengeMetric.workouts => 'workouts',
    ChallengeMetric.streakDays => 'days',
    ChallengeMetric.minutes => 'min',
    ChallengeMetric.volumeKg => 'kg',
    ChallengeMetric.exerciseReps => 'reps',
    ChallengeMetric.holdSeconds => 's',
  };
}

/// A time-boxed goal a member can join. Pure domain object — no Flutter.
class Challenge extends Equatable {
  const Challenge({
    required this.id,
    required this.title,
    required this.tagline,
    required this.description,
    required this.icon,
    required this.metric,
    required this.target,
    required this.durationDays,
    required this.difficulty,
    this.exerciseId,
    this.exerciseName,
  });

  final String id;
  final String title;
  final String tagline;
  final String description;

  /// Icon key resolved by the UI (`flag`, `fire`, `timer`, …).
  final String icon;
  final ChallengeMetric metric;
  final int target;
  final int durationDays;
  final Difficulty difficulty;
  final String? exerciseId;
  final String? exerciseName;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    tagline,
    description,
    icon,
    metric,
    target,
    durationDays,
    difficulty,
    exerciseId,
    exerciseName,
  ];
}

/// A member's participation in one challenge.
class ChallengeEnrollment extends Equatable {
  const ChallengeEnrollment({
    required this.challengeId,
    required this.joinedAt,
    this.completedAt,
  });

  final String challengeId;
  final DateTime joinedAt;
  final DateTime? completedAt;

  ChallengeEnrollment copyWith({DateTime? completedAt}) => ChallengeEnrollment(
    challengeId: challengeId,
    joinedAt: joinedAt,
    completedAt: completedAt ?? this.completedAt,
  );

  @override
  List<Object?> get props => <Object?>[challengeId, joinedAt, completedAt];
}

enum ChallengeStatus { available, active, completed, expired }

/// A challenge together with the member's live progress toward it.
class ChallengeProgress extends Equatable {
  const ChallengeProgress({
    required this.challenge,
    required this.status,
    required this.current,
    this.enrollment,
    this.now,
  });

  final Challenge challenge;
  final ChallengeStatus status;

  /// Current value of [Challenge.metric] inside the challenge window.
  final int current;
  final ChallengeEnrollment? enrollment;
  final DateTime? now;

  double get fraction =>
      challenge.target == 0 ? 0 : (current / challenge.target).clamp(0.0, 1.0);

  DateTime? get deadline =>
      enrollment?.joinedAt.add(Duration(days: challenge.durationDays));

  /// Whole days left including today; 0 when the window has closed.
  int get daysLeft {
    final end = deadline;
    if (end == null) return challenge.durationDays;
    final remaining = end.difference(now ?? DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isActive => status == ChallengeStatus.active;
  bool get isCompleted => status == ChallengeStatus.completed;

  @override
  List<Object?> get props => <Object?>[
    challenge,
    status,
    current,
    enrollment,
    now,
  ];
}
