import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/app/routing/app_routes.dart';
import 'package:forge_gym/core/constants/app_constants.dart';
import 'package:forge_gym/core/utils/formatters.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/progress/domain/entities/progress_summary.dart';
import 'package:forge_gym/features/progress/domain/entities/weight_entry.dart';
import 'package:forge_gym/features/progress/presentation/cubit/progress_cubit.dart';
import 'package:forge_gym/features/progress/presentation/cubit/progress_state.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:go_router/go_router.dart';

/// Training statistics, weekly activity chart, body-weight tracking,
/// and finished-workout history.
///
/// Refreshes itself when a workout finishes or a weight is logged (the
/// cubit listens to the repositories), and supports pull-to-refresh.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProgressCubit>()..load(),
      child: const _ProgressView(),
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: BlocConsumer<ProgressCubit, ProgressState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          return switch (state.status) {
            ProgressStatus.initial ||
            ProgressStatus.loading => AppSkeletonList.dashboard(),
            ProgressStatus.error => AppErrorView(
              message: state.errorMessage ?? 'Something went wrong.',
              onRetry: () => context.read<ProgressCubit>().load(),
            ),
            ProgressStatus.loaded ||
            ProgressStatus.savingWeight => _Loaded(state: state),
          };
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});

  final ProgressState state;

  @override
  Widget build(BuildContext context) {
    final summary =
        state.summary ??
        const ProgressSummary(
          workoutsThisWeek: 0,
          currentStreakDays: 0,
          totalWorkouts: 0,
          totalMinutes: 0,
          totalVolumeKg: 0,
        );
    var reveal = 0;
    return RefreshIndicator(
      onRefresh: () => context.read<ProgressCubit>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: <Widget>[
          AppReveal(
            index: reveal++,
            child: _HeroCard(summary: summary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppReveal(
            index: reveal++,
            child: _StatTiles(summary: summary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppReveal(
            index: reveal++,
            child: _WeeklyChart(counts: state.weeklyCounts),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppReveal(
            index: reveal++,
            child: _BodyWeightCard(state: state),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppReveal(
            index: reveal++,
            child: _History(history: state.history),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero: streak + weekly goal ring
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary});

  final ProgressSummary summary;

  String get _goalMessage {
    final remaining = AppConstants.weeklyWorkoutGoal - summary.workoutsThisWeek;
    if (summary.workoutsThisWeek == 0) {
      return 'No sessions yet this week — a short one still counts.';
    }
    if (remaining <= 0) return 'Weekly goal reached. Keep the momentum!';
    return remaining == 1
        ? 'One more session to hit this week\'s goal.'
        : '$remaining more sessions to hit this week\'s goal.';
  }

  @override
  Widget build(BuildContext context) {
    final streak = summary.currentStreakDays;
    return Semantics(
      label:
          '$streak day streak. ${summary.workoutsThisWeek} of '
          '${AppConstants.weeklyWorkoutGoal} workouts this week. $_goalMessage',
      explicitChildNodes: false,
      child: AppPhotoHero(
        imageAsset: 'assets/exercises/romanian-deadlift/thumb.jpg',
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'CURRENT STREAK',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      AppCountUp(
                        value: streak.toDouble(),
                        format: (v) => v.round().toString(),
                        style: AppTextStyles.display.copyWith(
                          color: Colors.white,
                          fontSize: 44,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          streak == 1 ? 'day' : 'days',
                          style: AppTextStyles.title.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _goalMessage,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            _GoalRing(
              done: summary.workoutsThisWeek,
              goal: AppConstants.weeklyWorkoutGoal,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalRing extends StatelessWidget {
  const _GoalRing({required this.done, required this.goal});

  final int done;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final target = (done / goal).clamp(0.0, 1.0);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: 96,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: target),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => CustomPaint(
          painter: _RingPainter(
            progress: value,
            track: Colors.white.withValues(alpha: 0.25),
            fill: Colors.white,
          ),
          child: child,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$done/$goal',
                style: AppTextStyles.title.copyWith(
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              Text(
                'this week',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = Offset.zero & size;
    final inner = rect.deflate(stroke / 2);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(inner, 0, math.pi * 2, false, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
        inner,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.fill != fill;
}

// ---------------------------------------------------------------------------
// Stat tiles
// ---------------------------------------------------------------------------

class _StatTiles extends StatelessWidget {
  const _StatTiles({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: AppStatTile(
            icon: Icons.fitness_center_rounded,
            value: summary.totalWorkouts.toDouble(),
            label: 'Workouts',
            format: (v) => v.round().toString(),
            semanticLabel: '${summary.totalWorkouts} total workouts',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppStatTile(
            icon: Icons.timer_outlined,
            value: summary.totalMinutes.toDouble(),
            label: 'Minutes',
            format: Formatters.grouped,
            tint: scheme.tertiary,
            semanticLabel: '${summary.totalMinutes} minutes trained',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppStatTile(
            icon: Icons.scale_outlined,
            value: summary.totalVolumeKg,
            label: 'kg lifted',
            format: Formatters.grouped,
            tint: scheme.secondary,
            semanticLabel:
                '${Formatters.grouped(summary.totalVolumeKg)} kilograms lifted',
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly chart
// ---------------------------------------------------------------------------

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.counts});

  final List<int> counts;

  static const _labels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final max = counts.fold<int>(1, (m, c) => c > m ? c : m);
    final total = counts.fold<int>(0, (sum, c) => sum + c);
    final todayIndex = DateTime.now().weekday - 1;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: 'This week',
          padding: EdgeInsets.zero,
          trailing: Text(
            total == 1 ? '1 workout' : '$total workouts',
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          semanticLabel:
              'Workouts this week: ${counts.join(', ')} for Monday to Sunday',
          child: SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (var i = 0; i < 7; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _Bar(
                      count: counts[i],
                      fraction: counts[i] / max,
                      label: _labels[i],
                      isToday: i == todayIndex,
                      delay: reduceMotion
                          ? Duration.zero
                          : Duration(milliseconds: 40 * i),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.count,
    required this.fraction,
    required this.label,
    required this.isToday,
    required this.delay,
  });

  final int count;
  final double fraction;
  final String label;
  final bool isToday;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = count > 0;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: Text(
            '$count',
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 0.1 + 0.9 * fraction),
              duration: reduceMotion
                  ? Duration.zero
                  : Duration(milliseconds: 600 + delay.inMilliseconds),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => FractionallySizedBox(
                heightFactor: value.clamp(0.1, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: active
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: isToday
              ? BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                )
              : null,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isToday
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Body weight
// ---------------------------------------------------------------------------

class _BodyWeightCard extends StatelessWidget {
  const _BodyWeightCard({required this.state});

  final ProgressState state;

  Future<void> _logWeight(BuildContext context) async {
    final cubit = context.read<ProgressCubit>();
    final latest = state.latestWeight;
    final value = await showAppInputSheet(
      context,
      title: 'Log body weight',
      message: 'Weigh in at the same time of day for the most useful trend.',
      label: 'Weight',
      hint: latest != null ? Formatters.number(latest.weightKg) : 'e.g. 82.5',
      suffixText: 'kg',
      icon: Icons.monitor_weight_outlined,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (text) {
        final parsed = double.tryParse(text.replaceAll(',', '.'));
        if (parsed == null || parsed <= 0 || parsed > 500) {
          return 'Enter a weight between 1 and 500 kg.';
        }
        return null;
      },
    );
    if (value == null) return;
    await cubit.logWeight(double.parse(value.replaceAll(',', '.')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weights = state.weights;
    final latest = state.latestWeight;
    final previous = weights.length > 1 ? weights[1] : null;
    final delta = latest != null && previous != null
        ? latest.weightKg - previous.weightKg
        : null;
    final saving = state.status == ProgressStatus.savingWeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: 'Body weight',
          padding: EdgeInsets.zero,
          trailing: AppButton(
            label: 'Log',
            icon: Icons.add_rounded,
            size: AppButtonSize.medium,
            variant: AppButtonVariant.secondary,
            expanded: false,
            isLoading: saving,
            onPressed: () => _logWeight(context),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          semanticLabel: latest != null
              ? 'Latest weight ${Formatters.kg(latest.weightKg)}, '
                    'logged ${Formatters.relativeDate(latest.date)}'
              : 'No body weight logged yet',
          child: latest == null
              ? _EmptyWeight(onLog: () => _logWeight(context))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        AppCountUp(
                          value: latest.weightKg,
                          format: Formatters.number,
                          style: AppTextStyles.display.copyWith(
                            color: scheme.onSurface,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'kg',
                            style: AppTextStyles.title.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _DeltaChip(delta: delta),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Logged ${Formatters.relativeDate(latest.date)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (weights.length > 1) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        height: 72,
                        child: _Sparkline(
                          values: weights
                              .take(10)
                              .toList()
                              .reversed
                              .map((e) => e.weightKg)
                              .toList(),
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (final entry in weights.skip(1).take(3))
                        _WeightRow(entry: entry),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _EmptyWeight extends StatelessWidget {
  const _EmptyWeight({required this.onLog});

  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            Icons.monitor_weight_outlined,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('No entries yet', style: AppTextStyles.subtitle),
              const SizedBox(height: 2),
              Text(
                'Log your first weigh-in to start a trend line.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});

  final double? delta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = delta;
    final String text;
    final IconData icon;
    final Color colour;
    if (value == null) {
      text = 'First entry';
      icon = Icons.flag_outlined;
      colour = scheme.onSurfaceVariant;
    } else if (value.abs() < 0.05) {
      text = 'No change';
      icon = Icons.remove_rounded;
      colour = scheme.onSurfaceVariant;
    } else if (value > 0) {
      text = '+${Formatters.number(value)} kg';
      icon = Icons.north_east_rounded;
      colour = AppColors.warning;
    } else {
      text = '−${Formatters.number(value.abs())} kg';
      icon = Icons.south_east_rounded;
      colour = AppColors.success;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: colour),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: colour,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  const _WeightRow({required this.entry});

  final WeightEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Icon(Icons.history_rounded, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              Formatters.relativeDate(entry.date),
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(Formatters.kg(entry.weightKg), style: AppTextStyles.subtitle),
        ],
      ),
    );
  }
}

/// Draws [values] (oldest → newest) as a smooth line that animates in
/// from left to right, with a soft gradient fill underneath.
class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => CustomPaint(
        painter: _SparklinePainter(
          values: values,
          progress: progress,
          color: color,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.progress,
    required this.color,
  });

  final List<double> values;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final span = (max - min).abs() < 0.001 ? 1.0 : max - min;
    const pad = 6.0;
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          i * (size.width / (values.length - 1)),
          pad + (size.height - pad * 2) * (1 - (values[i] - min) / span),
        ),
    ];

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      line.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    // Reveal progressively by clipping to the animated width.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    final fill = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    if (progress >= 0.999) {
      final last = points.last;
      canvas.drawCircle(last, 6, Paint()..color = color.withValues(alpha: 0.2));
      canvas.drawCircle(last, 3.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.progress != progress || old.values != values || old.color != color;
}

// ---------------------------------------------------------------------------
// History
// ---------------------------------------------------------------------------

class _History extends StatelessWidget {
  const _History({required this.history});

  final List<CompletedWorkout> history;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: 'History',
          padding: EdgeInsets.zero,
          trailing: history.isEmpty
              ? null
              : Text(
                  history.length == 1
                      ? '1 session'
                      : '${history.length} sessions',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (history.isEmpty)
          AppCard(
            child: Column(
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    size: 32,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'No finished workouts yet',
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Complete a workout to see it here.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Start a workout',
                  icon: Icons.play_arrow_rounded,
                  size: AppButtonSize.medium,
                  expanded: false,
                  onPressed: () => context.go(AppRoutes.workouts),
                ),
              ],
            ),
          )
        else
          for (var i = 0; i < history.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppReveal(
                index: i,
                stagger: const Duration(milliseconds: 40),
                child: _HistoryTile(workout: history[i]),
              ),
            ),
      ],
    );
  }
}

class _HistoryTile extends StatefulWidget {
  const _HistoryTile({required this.workout});

  final CompletedWorkout workout;

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile> {
  bool _expanded = false;

  /// `3 × 10 × 60 kg`, `3 × 12` (bodyweight), `3 × 30 s`, or a per-set
  /// breakdown when sets differ.
  static String setsSummary(CompletedExercise exercise) {
    if (exercise.sets.isEmpty) return 'No sets logged';
    final timed = exercise.tracking.isTimed;
    String one(PerformedSet s) {
      if (timed) return '${s.reps} s';
      return s.weightKg > 0
          ? '${s.reps} × ${Formatters.kg(s.weightKg)}'
          : '${s.reps}';
    }

    final first = exercise.sets.first;
    final uniform = exercise.sets.every(
      (s) => s.reps == first.reps && s.weightKg == first.weightKg,
    );
    if (uniform) return '${exercise.sets.length} × ${one(first)}';
    return exercise.sets.map(one).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final workout = widget.workout;
    return AppCard(
      onTap: () => setState(() => _expanded = !_expanded),
      semanticLabel:
          'Finished workout: ${workout.workoutName} on '
          '${Formatters.date(workout.finishedAt)}. '
          '${_expanded ? 'Collapse' : 'Expand'} details.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _DateBadge(date: workout.finishedAt),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      workout.workoutName,
                      style: AppTextStyles.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        _Meta(
                          icon: Icons.timer_outlined,
                          text: Formatters.durationSeconds(
                            workout.durationSeconds,
                          ),
                        ),
                        _Meta(
                          icon: Icons.repeat_rounded,
                          text: '${workout.totalSets} sets',
                        ),
                        _Meta(
                          icon: Icons.scale_outlined,
                          text: Formatters.kg(workout.totalVolumeKg),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: Icon(
                  Icons.expand_more_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Divider(height: 1, color: scheme.outlineVariant),
                        const SizedBox(height: AppSpacing.sm),
                        if (workout.exercises.isEmpty)
                          Text(
                            'No sets were logged in this session.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          )
                        else
                          for (final exercise in workout.exercises)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      exercise.exerciseName,
                                      style: AppTextStyles.body,
                                    ),
                                  ),
                                  Text(
                                    setsSummary(exercise),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: <Widget>[
          Text(
            '${date.day}',
            style: AppTextStyles.title.copyWith(
              color: scheme.onPrimaryContainer,
              height: 1.1,
            ),
          ),
          Text(
            Formatters.monthShort(date).toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: scheme.onPrimaryContainer,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
