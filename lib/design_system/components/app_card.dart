import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/spacing/app_spacing.dart';

/// Generic surface card. Flat (no elevation) with a subtle border —
/// the premium look used across the app. Tappable when [onTap] is set.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.lg);

    // The inner Material gives Material-dependent descendants (ListTile,
    // InkWell, SwitchListTile, …) an ancestor to paint on. Without it,
    // Flutter asserts in debug builds when such a widget sits inside this
    // card's DecoratedBox, because ink effects would be hidden behind the
    // card background.
    final Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: borderRadius,
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );

    if (semanticLabel == null) return card;
    // explicitChildNodes keeps the card's own label exact ("Push Up.
    // Beginner.") instead of merging every inner text/image label into one
    // verbose announcement; inner content stays separately navigable.
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      explicitChildNodes: true,
      child: card,
    );
  }
}
