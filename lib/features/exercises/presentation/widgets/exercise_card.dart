import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

/// Library row: a tall photo panel with a play badge, name, target muscles,
/// equipment and level. Thumbnails only — the demo clip downloads on the
/// detail screen, never in a list.
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({super.key, required this.exercise, this.onTap});

  final Exercise exercise;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppPressable(
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        semanticLabel:
            '${exercise.name}. ${exercise.difficulty.label}. '
            '${exercise.equipment.label}.',
        // Minimum height keeps the list rhythm; IntrinsicHeight lets a
        // two-line name plus wrapped tags grow the row (and stretch the
        // thumbnail) instead of overflowing on narrow phones.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 132),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  width: 118,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Hero(
                        tag: 'exercise-thumb-${exercise.id}',
                        child: Image.asset(
                          exercise.thumbnailAsset,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: scheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.fitness_center,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      if (exercise.videoAsset != null)
                        Center(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: AppColors.emberLight,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          exercise.name,
                          style: AppTextStyles.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          exercise.primaryMuscles
                              .map((m) => m.label)
                              .join(', '),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Wrap, not Row: on a 360 dp phone the second tag
                        // would otherwise be squeezed to "Dum…".
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: <Widget>[
                            _Tag(
                              icon: _levelIcon(exercise.difficulty),
                              label: exercise.difficulty.label,
                              colour: _levelColour(exercise.difficulty, scheme),
                            ),
                            _Tag(
                              icon: Icons.fitness_center_rounded,
                              label: exercise.equipment.label,
                              colour: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Icon(
                    Icons.chevron_right,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _levelIcon(Difficulty level) => switch (level) {
    Difficulty.beginner => Icons.signal_cellular_alt_1_bar_rounded,
    Difficulty.intermediate => Icons.signal_cellular_alt_2_bar_rounded,
    Difficulty.advanced => Icons.signal_cellular_alt_rounded,
  };

  static Color _levelColour(Difficulty level, ColorScheme scheme) =>
      switch (level) {
        Difficulty.beginner => AppColors.success,
        Difficulty.intermediate => scheme.primary,
        Difficulty.advanced => const Color(0xFF7C3AED),
      };
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.colour});

  final IconData icon;
  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: colour),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: colour,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
