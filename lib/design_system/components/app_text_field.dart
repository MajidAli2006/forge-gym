import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/typography/app_text_styles.dart';

/// Consistent text input. Visual decoration comes from the theme's
/// [InputDecorationTheme]; this wrapper carries the API features use.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.focusNode,
    this.onSubmitted,
    this.suffixText,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  /// Requests focus (and opens the keyboard) as soon as the field appears.
  /// Use for single-field dialogs and sheets.
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  /// Unit shown at the trailing edge, e.g. `kg` or `cm`.
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      autofocus: autofocus,
      focusNode: focusNode,
      onFieldSubmitted: onSubmitted,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        suffixText: suffixText,
      ),
    );
  }
}
