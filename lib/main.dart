import 'main_development.dart' as development;

/// Default entry point (`flutter run`) uses the development environment.
/// Use `--target lib/main_staging.dart` / `--target lib/main_production.dart`
/// for the other flavors.
Future<void> main() => development.main();
