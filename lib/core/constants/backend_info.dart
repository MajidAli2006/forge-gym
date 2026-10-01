/// Which backend the running app was wired to at startup.
///
/// Registered by DI so presentation can adapt small things (for example the
/// "Fill demo credentials" shortcut only makes sense against the mock).
class BackendInfo {
  const BackendInfo({required this.firebase, required this.firebaseAuth});

  /// True when Firebase initialised and the Firebase-backed services
  /// (push, media) were registered.
  final bool firebase;

  /// True when accounts are backed by Firebase Authentication.
  final bool firebaseAuth;

  bool get usesMockAuth => !firebaseAuth;
}
