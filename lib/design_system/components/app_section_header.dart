import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/spacing/app_spacing.dart';

/// Section title row with an optional trailing action
/// (e.g. "See all").
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Custom trailing widget (a count, a small button). Takes precedence
  /// over [actionLabel].
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (trailing != null)
            trailing!
          else if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
