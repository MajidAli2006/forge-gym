import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/challenges/domain/entities/challenge.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

/// Icon + accent colour for a challenge, resolved from its data keys.
abstract final class ChallengeLook {
  static IconData icon(String key) => switch (key) {
    'fire' => Icons.local_fire_department_rounded,
    'pushup' => Icons.fitness_center_rounded,
    'timer' => Icons.timer_rounded,
    'calendar' => Icons.calendar_month_rounded,
    'scale' => Icons.scale_rounded,
    'clock' => Icons.schedule_rounded,
    'trophy' => Icons.emoji_events_rounded,
    _ => Icons.flag_rounded,
  };

  static List<Color> gradient(Difficulty difficulty) => switch (difficulty) {
    Difficulty.beginner => const <Color>[Color(0xFF0E7C5B), Color(0xFF34D399)],
    Difficulty.intermediate => const <Color>[
      AppColors.emberLight,
      AppColors.emberDark,
    ],
    Difficulty.advanced => const <Color>[Color(0xFF312E81), Color(0xFF7C3AED)],
  };
}

/// Full-width challenge card with progress, days left and a Join / Leave
/// action. Used on the challenges screen; [compact] gives the narrower
/// carousel variant used on Home.
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.progress,
    this.onJoin,
    this.onLeave,
    this.onTap,
    this.compact = false,
  });

  final ChallengeProgress progress;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final challenge = progress.challenge;
    final colours = ChallengeLook.gradient(challenge.difficulty);
    final metric = challenge.metric;
    final statusLabel = switch (progress.status) {
      ChallengeStatus.available => challenge.difficulty.label,
      ChallengeStatus.active =>
        progress.daysLeft == 1
            ? '1 day left'
            : '${progress.daysLeft} days left',
      ChallengeStatus.completed => 'Completed',
      ChallengeStatus.expired => 'Ended',
    };
    return AppPressable(
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        semanticLabel:
            '${challenge.title}. ${challenge.tagline}. $statusLabel. '
            '${metric.format(progress.current)} of ${metric.format(challenge.target)}.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colours,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: compact ? 40 : 48,
                    height: compact ? 40 : 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      progress.isCompleted
                          ? Icons.emoji_events_rounded
                          : ChallengeLook.icon(challenge.icon),
                      color: Colors.white,
                      size: compact ? 22 : 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          challenge.title,
                          style:
                              (compact
                                      ? AppTextStyles.subtitle
                                      : AppTextStyles.title)
                                  .copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          challenge.tagline,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          // Two lines so the goal is never cut off on
                          // narrow phones ("Finish 3 workouts in 2 w…").
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      statusLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          progress.status == ChallengeStatus.available
                              ? '${metric.format(challenge.target)} in '
                                    '${challenge.durationDays} days'
                              : '${metric.format(progress.current)} of '
                                    '${metric.format(challenge.target)}',
                          style: AppTextStyles.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (progress.status != ChallengeStatus.available)
                        Text(
                          '${(progress.fraction * 100).round()}%',
                          style: AppTextStyles.subtitle.copyWith(
                            color: progress.isCompleted
                                ? AppColors.success
                                : scheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: progress.status == ChallengeStatus.available
                            ? 0
                            : progress.fraction,
                      ),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: scheme.surfaceContainerHighest,
                        color: progress.isCompleted
                            ? AppColors.success
                            : colours.last,
                      ),
                    ),
                  ),
                  if (!compact &&
                      (onJoin != null || onLeave != null)) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    if (onJoin != null)
                      AppButton(
                        label: progress.status == ChallengeStatus.expired
                            ? 'Try again'
                            : 'Join challenge',
                        icon: Icons.add_rounded,
                        size: AppButtonSize.medium,
                        onPressed: onJoin,
                      )
                    else if (onLeave != null)
                      AppButton(
                        label: 'Leave challenge',
                        variant: AppButtonVariant.text,
                        size: AppButtonSize.medium,
                        onPressed: onLeave,
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
