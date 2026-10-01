import 'package:forge_gym/features/auth/domain/validators/auth_rules.dart';

/// Form-field validators for the auth screens. Thin adapters over the
/// domain [AuthRules] so the single source of truth stays in the domain.
abstract final class AuthValidators {
  static String? validateEmail(String? value) =>
      AuthRules.validateEmail(value?.trim() ?? '');

  static String? validatePassword(String? value) =>
      AuthRules.validatePassword(value ?? '');

  static String? validateName(String? value) =>
      AuthRules.validateName(value ?? '');
}
