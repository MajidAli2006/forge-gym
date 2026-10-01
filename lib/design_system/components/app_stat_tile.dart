import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/components/app_card.dart';
import 'package:forge_gym/design_system/components/app_motion.dart';
import 'package:forge_gym/design_system/spacing/app_spacing.dart';
import 'package:forge_gym/design_system/typography/app_text_styles.dart';

/// Compact metric tile: tinted icon badge, animated value, label.
///
/// Used for dashboards (progress, home) and the profile stats row. The
/// value counts up on first build and whenever it changes.
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.format,
    this.tint,
    this.semanticLabel,
    this.onTap,
  });

  final IconData icon;
  final double value;
  final String label;
  final String Function(double value) format;

  /// Badge colour; defaults to the theme primary.
  final Color? tint;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colour = tint ?? scheme.primary;
    return AppCard(
      onTap: onTap,
      semanticLabel: semanticLabel ?? '${format(value)} $label',
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colour.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 20, color: colour),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCountUp(
            value: value,
            format: format,
            style: AppTextStyles.headline.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
