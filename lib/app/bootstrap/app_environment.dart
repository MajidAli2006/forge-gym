/// Where the `media_upload` folder is hosted for real builds.
///
/// Override at build time without touching code:
///
///     flutter build apk --release --target lib/main_production.dart \
///       --dart-define=MEDIA_BASE_URL=https://<your-host>
///
/// Any static host works (GitHub Pages, Cloudflare Pages/R2, Firebase
/// Storage, S3, a plain web server). The folder layout must stay
/// `exercises/<exercise-id>/demo.mp4`. See `media_upload/README.md`.
///
/// Default: the public GitHub Pages site built from `media_upload`
/// (repository MajidAli2006/forge-gym-media). Pass `firebase` to use the
/// project's Storage bucket once it exists.
const String kProductionMediaBaseUrl = String.fromEnvironment(
  'MEDIA_BASE_URL',
  defaultValue: 'https://majidali2006.github.io/forge-gym-media',
);

/// Special value for `mediaBaseUrl`: fetch clips from the project's Firebase
/// Storage bucket (`exercises/<id>/demo.mp4` objects) via signed download
/// URLs instead of a plain static host.
const String kFirebaseMediaHost = 'firebase';

/// Build flavors supported by the app.
///
/// Backend configuration lives in [EnvConfig] and is injected — it must never
/// be scattered across features.
enum AppEnvironment { development, staging, production }

/// Environment-specific configuration, resolved once at startup.
class EnvConfig {
  const EnvConfig({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    required this.mediaBaseUrl,
    required this.enableAnalytics,
    required this.logNetworkTraffic,
    this.useFirebaseAuth = true,
  });

  factory EnvConfig.forEnvironment(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.development:
        return const EnvConfig(
          environment: AppEnvironment.development,
          appName: 'Forge Gym (Dev)',
          // Placeholder: no backend exists yet. Repositories currently resolve
          // to local mocks; this URL is used once Api* repositories land.
          apiBaseUrl: 'https://api.dev.forgegym.example',
          // 10.0.2.2 is the Android emulator's alias for the host machine.
          // Serve the `media_upload` folder locally with:
          //   python3 -m http.server 8787 --directory ../media_upload
          // (overridable with --dart-define=MEDIA_BASE_URL=...)
          mediaBaseUrl: String.fromEnvironment(
            'MEDIA_BASE_URL',
            defaultValue: 'http://10.0.2.2:8787',
          ),
          // Dev signs in with the local demo account unless explicitly
          // pointed at Firebase Auth (--dart-define=FIREBASE_AUTH=true), so
          // the app stays testable before Email/Password is enabled.
          useFirebaseAuth: bool.fromEnvironment('FIREBASE_AUTH'),
          enableAnalytics: false,
          logNetworkTraffic: true,
        );
      case AppEnvironment.staging:
        return const EnvConfig(
          environment: AppEnvironment.staging,
          appName: 'Forge Gym (Stg)',
          apiBaseUrl: 'https://api.staging.forgegym.example',
          mediaBaseUrl: kProductionMediaBaseUrl,
          enableAnalytics: true,
          logNetworkTraffic: true,
        );
      case AppEnvironment.production:
        return const EnvConfig(
          environment: AppEnvironment.production,
          appName: 'Forge Gym',
          apiBaseUrl: 'https://api.forgegym.example',
          mediaBaseUrl: kProductionMediaBaseUrl,
          enableAnalytics: true,
          logNetworkTraffic: false,
        );
    }
  }

  final AppEnvironment environment;

  /// Marketing name shown in the OS and in-app; the build's own version
  /// string comes from `AppInfo` (package_info_plus) at runtime.
  final String appName;
  final String apiBaseUrl;

  /// Root URL that exercise demo clips are downloaded from. The app never
  /// bundles video: `<mediaBaseUrl>/exercises/<id>/demo.mp4` is fetched the
  /// first time an exercise is opened and cached on the device.
  final String mediaBaseUrl;

  /// Whether accounts live in Firebase Authentication (when Firebase is
  /// available) or in the local mock. Always true outside development.
  final bool useFirebaseAuth;
  final bool enableAnalytics;
  final bool logNetworkTraffic;

  bool get usesFirebaseMedia => mediaBaseUrl == kFirebaseMediaHost;

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;
}
