import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/spacing/app_spacing.dart';
import 'package:forge_gym/design_system/typography/app_text_styles.dart';

/// Button variants. Never add feature-specific variants — compose instead.
enum AppButtonVariant { primary, secondary, outline, text }

/// Large (56dp) is the default for primary actions — usable mid-workout.
/// Medium (48dp) for secondary/compact placements. Never smaller.
enum AppButtonSize { large, medium }

/// Primary action button for the app.
///
/// Handles loading and disabled states consistently, exposes a semantic
/// label, and guarantees a minimum 48dp touch target.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;

  /// When true (default) the button fills its parent's width.
  final bool expanded;

  /// Renders the primary variant in the error colour for irreversible
  /// actions (discard, sign out). Ignored by other variants.
  final bool destructive;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final minHeight = switch (widget.size) {
      AppButtonSize.large => 56.0,
      AppButtonSize.medium => 48.0,
    };

    final style = ButtonStyle(
      backgroundColor:
          widget.destructive && widget.variant == AppButtonVariant.primary
          ? WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? scheme.onSurface.withValues(alpha: 0.12)
                  : scheme.error,
            )
          : null,
      foregroundColor:
          widget.destructive && widget.variant == AppButtonVariant.primary
          ? WidgetStatePropertyAll(scheme.onError)
          : null,
      minimumSize: WidgetStatePropertyAll(Size(64, minHeight)),
      textStyle: const WidgetStatePropertyAll(AppTextStyles.button),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );

    final spinnerColor = widget.variant == AppButtonVariant.primary
        ? scheme.onPrimary
        : scheme.primary;

    final Widget content = widget.isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(widget.label, overflow: TextOverflow.ellipsis),
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.icon != null) ...<Widget>[
                Icon(widget.icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    // A null onPressed renders the disabled state and removes the action
    // from the semantics tree automatically.
    final VoidCallback? onTap = widget._enabled ? widget.onPressed : null;

    final Widget button = switch (widget.variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: onTap,
        style: style,
        child: content,
      ),
      AppButtonVariant.secondary => FilledButton.tonal(
        onPressed: onTap,
        style: style,
        child: content,
      ),
      AppButtonVariant.outline => OutlinedButton(
        onPressed: onTap,
        style: style,
        child: content,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: onTap,
        style: style,
        child: content,
      ),
    };

    // Subtle press scale. A Listener observes pointer events without
    // claiming them, so the Material button keeps its own tap handling.
    final Widget pressable = Listener(
      onPointerDown: widget._enabled ? (_) => _setPressed(true) : null,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: button,
      ),
    );

    final Widget withSemantics = Semantics(
      button: true,
      enabled: widget._enabled,
      label: widget.isLoading ? '${widget.label}, loading' : widget.label,
      child: pressable,
    );

    if (!widget.expanded) return withSemantics;
    return SizedBox(width: double.infinity, child: withSemantics);
  }
}
