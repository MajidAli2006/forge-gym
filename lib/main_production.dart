import 'package:forge_gym/app/bootstrap/app_environment.dart';
import 'package:forge_gym/app/bootstrap/bootstrap.dart';

/// Production flavor: analytics on, network traffic logging off.
Future<void> main() => bootstrap(AppEnvironment.production);
