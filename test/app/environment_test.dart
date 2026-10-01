import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/app/bootstrap/app_environment.dart';

void main() {
  group('EnvConfig', () {
    test('development disables analytics and logs network traffic', () {
      final config = EnvConfig.forEnvironment(AppEnvironment.development);

      expect(config.environment, AppEnvironment.development);
      expect(config.appName, isNotEmpty);
      expect(config.apiBaseUrl, isNotEmpty);
      expect(config.enableAnalytics, isFalse);
      expect(config.logNetworkTraffic, isTrue);
      expect(config.isDevelopment, isTrue);
      expect(config.isProduction, isFalse);
    });

    test('staging enables analytics and logs network traffic', () {
      final config = EnvConfig.forEnvironment(AppEnvironment.staging);

      expect(config.enableAnalytics, isTrue);
      expect(config.logNetworkTraffic, isTrue);
      expect(config.isDevelopment, isFalse);
      expect(config.isProduction, isFalse);
    });

    test('production enables analytics and silences network logging', () {
      final config = EnvConfig.forEnvironment(AppEnvironment.production);

      expect(config.enableAnalytics, isTrue);
      expect(config.logNetworkTraffic, isFalse);
      expect(config.isProduction, isTrue);
    });

    test('each environment has a distinct base URL', () {
      final urls = AppEnvironment.values
          .map((e) => EnvConfig.forEnvironment(e).apiBaseUrl)
          .toSet();

      expect(urls, hasLength(AppEnvironment.values.length));
    });
  });
}
