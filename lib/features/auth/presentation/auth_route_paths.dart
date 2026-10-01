/// Auth route paths.
///
/// The app router (lib/app) maps these to screens and will expose them via
/// [AppRoutes]; screens reference these constants — never raw strings.
abstract final class AuthRoutePaths {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
}
