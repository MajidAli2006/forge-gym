import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/spacing/app_spacing.dart';
import 'package:forge_gym/design_system/typography/app_text_styles.dart';

/// Selectable pill chip (filters, categories). Single-select semantics;
/// groups of these manage their own selection state in the feature.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.avatar,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: avatar,
      showCheckmark: false,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      selectedColor: scheme.primaryContainer,
      backgroundColor: scheme.surfaceContainerLow,
      side: BorderSide(
        color: selected ? Colors.transparent : scheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }
}
