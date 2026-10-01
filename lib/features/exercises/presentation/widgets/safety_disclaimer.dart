import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/design_system.dart';

/// Standing safety note shown under every exercise's guidance.
/// Plain-English, non-alarmist, and never presented as medical advice.
class SafetyDisclaimer extends StatelessWidget {
  const SafetyDisclaimer({super.key});

  static const String text =
      'Exercise guidance is for general informational purposes. '
      'Use a weight and technique appropriate for your ability, and seek '
      'professional advice if you are unsure how to perform an exercise safely.';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.health_and_safety_outlined,
            size: 20,
            color: scheme.onSurfaceVariant,
            semanticLabel: 'Safety note',
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
