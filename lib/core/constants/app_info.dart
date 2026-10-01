import 'package:package_info_plus/package_info_plus.dart';

/// Build identity read from the platform at startup (pubspec `version`).
///
/// Registered in DI by bootstrap; screens read it to show "v0.2.0 (2)"
/// without hard-coding a string that drifts from `pubspec.yaml`.
class AppInfo {
  const AppInfo({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  static Future<AppInfo> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return AppInfo(version: info.version, buildNumber: info.buildNumber);
    } catch (_) {
      return const AppInfo(version: '', buildNumber: '');
    }
  }

  /// `v0.2.0 (2)`, or empty when unknown (tests, unsupported platform).
  String get label => version.isEmpty
      ? ''
      : 'v$version${buildNumber.isEmpty ? '' : ' ($buildNumber)'}';
}
