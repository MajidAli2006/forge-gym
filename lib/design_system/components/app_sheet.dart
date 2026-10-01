import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/components/app_button.dart';
import 'package:forge_gym/design_system/components/app_text_field.dart';
import 'package:forge_gym/design_system/spacing/app_spacing.dart';
import 'package:forge_gym/design_system/typography/app_text_styles.dart';

/// Modal sheets replace Material alert dialogs across the app: they slide
/// up from the bottom, sit in thumb reach, and carry an icon, a title, a
/// short message and one or two full-width actions.
///
/// Two helpers cover every current use:
/// - [showAppConfirmSheet] — yes/no decisions (finish, discard, sign out).
/// - [showAppInputSheet]   — a single numeric/text value (weight, age…).

/// Shows a confirmation sheet and resolves to `true` when the primary
/// action is chosen, `false` for cancel, and `null` when dismissed.
Future<bool?> showAppConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  IconData icon = Icons.help_outline,
  bool destructive = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => AppSheet(
      icon: icon,
      destructive: destructive,
      title: title,
      message: message,
      actions: <Widget>[
        AppButton(
          label: confirmLabel,
          onPressed: () => Navigator.of(sheetContext).pop(true),
          variant: AppButtonVariant.primary,
          destructive: destructive,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: cancelLabel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(sheetContext).pop(false),
        ),
      ],
    ),
  );
}

/// Shows a single-field input sheet. The field takes focus immediately,
/// the keyboard's done key submits, and [validator] errors render inline.
/// Resolves to the entered text, or `null` when cancelled.
Future<String?> showAppInputSheet(
  BuildContext context, {
  required String title,
  required String label,
  String? message,
  String? hint,
  String initialValue = '',
  String? suffixText,
  IconData icon = Icons.edit_outlined,
  TextInputType keyboardType = TextInputType.text,
  String saveLabel = 'Save',
  String? Function(String value)? validator,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _InputSheet(
      title: title,
      message: message,
      label: label,
      hint: hint,
      initialValue: initialValue,
      suffixText: suffixText,
      icon: icon,
      keyboardType: keyboardType,
      saveLabel: saveLabel,
      validator: validator,
    ),
  );
}

/// The sheet chrome: drag handle, icon badge, title, message, optional
/// body, and stacked actions. Compose custom sheets from this.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.body,
    this.actions = const <Widget>[],
    this.destructive = false,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final Widget? body;
  final List<Widget> actions;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = destructive ? scheme.error : scheme.primary;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xl + 8),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Header + body scroll when they are taller than the screen
            // allows (small phones, large text); the actions stay pinned
            // below so they are always visible.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 28, color: accent),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    Text(
                      title,
                      style: AppTextStyles.headline.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    if (message != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        message!,
                        style: AppTextStyles.body.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (body != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xl),
                      body!,
                    ],
                  ],
                ),
              ),
            ),
            if (actions.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }
}

class _InputSheet extends StatefulWidget {
  const _InputSheet({
    required this.title,
    required this.message,
    required this.label,
    required this.hint,
    required this.initialValue,
    required this.suffixText,
    required this.icon,
    required this.keyboardType,
    required this.saveLabel,
    required this.validator,
  });

  final String title;
  final String? message;
  final String label;
  final String? hint;
  final String initialValue;
  final String? suffixText;
  final IconData icon;
  final TextInputType keyboardType;
  final String saveLabel;
  final String? Function(String value)? validator;

  @override
  State<_InputSheet> createState() => _InputSheetState();
}

class _InputSheetState extends State<_InputSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initialValue.length,
        );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    final error = widget.validator?.call(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      icon: widget.icon,
      title: widget.title,
      message: widget.message,
      body: AppTextField(
        controller: _controller,
        label: widget.label,
        hint: widget.hint,
        errorText: _error,
        suffixText: widget.suffixText,
        keyboardType: widget.keyboardType,
        textInputAction: TextInputAction.done,
        autofocus: true,
        onSubmitted: (_) => _submit(),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
      ),
      actions: <Widget>[
        AppButton(label: widget.saveLabel, onPressed: _submit),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
