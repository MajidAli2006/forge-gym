import 'package:forge_gym/features/auth/data/datasources/auth_local_datasource.dart';

/// In-memory fake so auth tests never touch platform plugins.
class FakeAuthLocalDataSource implements AuthLocalDataSource {
  String? token;
  String? userJson;
  bool onboardingCompleted = false;
  final Map<String, String> profileNames = {};

  @override
  Future<void> saveSession({
    required String token,
    required String userJson,
  }) async {
    this.token = token;
    this.userJson = userJson;
  }

  @override
  Future<({String token, String userJson})?> readSession() async =>
      token == null || userJson == null
      ? null
      : (token: token!, userJson: userJson!);

  @override
  Future<void> clearSession() async {
    token = null;
    userJson = null;
  }

  @override
  Future<void> setOnboardingCompleted() async {
    onboardingCompleted = true;
  }

  @override
  Future<bool> isOnboardingCompleted() async => onboardingCompleted;

  @override
  Future<void> saveProfileName({
    required String email,
    required String name,
  }) async {
    profileNames[email.toLowerCase()] = name;
  }

  @override
  Future<String?> getProfileName(String email) async =>
      profileNames[email.toLowerCase()];
}
