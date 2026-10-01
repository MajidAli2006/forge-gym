import 'package:forge_gym/app/bootstrap/app_environment.dart';
import 'package:forge_gym/app/bootstrap/bootstrap.dart';

/// Staging flavor: analytics on, network traffic logging on.
Future<void> main() => bootstrap(AppEnvironment.staging);
