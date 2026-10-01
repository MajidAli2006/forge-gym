import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';

/// Workout plan card: gradient header with icon, name, difficulty chip,
/// duration/exercise count, and target muscles. Tapping opens the detail.
class WorkoutCard extends StatelessWidget {
  const WorkoutCard({
    super.key,
    required this.workout,
    this.coverAsset,
    this.onTap,
  });

  final Workout workout;

  /// Thumbnail of the plan's first exercise; the gradient header is the
  /// fallback when none is known.
  final String? coverAsset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cover = coverAsset;
    return AppPressable(
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        semanticLabel: '${workout.name} workout plan',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 150,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[AppColors.emberDark, AppColors.emberLight],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (cover != null)
                    Hero(
                      tag: 'workout-cover-${workout.id}',
                      child: Image.asset(
                        cover,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.35),
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    )
                  else
                    const Icon(
                      Icons.fitness_center,
                      size: 56,
                      color: Colors.white54,
                    ),
                  if (cover != null)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[Colors.transparent, Colors.black54],
                          stops: <double>[0.5, 1],
                        ),
                      ),
                    ),
                  Positioned(
                    left: AppSpacing.lg,
                    bottom: AppSpacing.md,
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${workout.durationMinutes} min',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        workout.isCustom
                            ? 'My routine · ${workout.difficulty.label}'
                            : workout.difficulty.label,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(workout.name, style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${workout.durationMinutes} min'
                    ' • ${workout.exerciseCount} exercises',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    workout.targetMuscles.map((m) => m.label).join(' • '),
                    style: AppTextStyles.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
