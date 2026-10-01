import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:forge_gym/firebase_options.dart';

/// Initialises Firebase once at startup.
///
/// The app must keep working without Firebase (widget tests, a build made
/// before `flutterfire configure` was run, a device with broken Play
/// services), so initialisation is best-effort and every Firebase-backed
/// service checks [isReady] before it is registered. When Firebase is not
/// ready the local/mock implementations are used instead.
abstract final class FirebaseBootstrap {
  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> initialize() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _ready = true;
    } catch (error) {
      debugPrint('[Firebase] not available: $error');
      _ready = false;
    }
  }
}
