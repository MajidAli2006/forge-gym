/// Pure input rules for authentication. No Flutter imports — safe for the
/// domain layer. Presentation form validators delegate to these.
abstract final class AuthRules {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Returns a user-facing error message, or null when valid.
  static String? validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return 'Enter your email address.';
    if (!_emailPattern.hasMatch(email)) {
      return 'That email address doesn\u2019t look right.';
    }
    return null;
  }

  static String? validatePassword(String value) {
    if (value.isEmpty) return 'Enter your password.';
    if (value.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  static String? validateName(String value) {
    if (value.trim().isEmpty) return 'Enter your name.';
    if (value.trim().length < 2) return 'Name must be at least 2 characters.';
    return null;
  }
}
