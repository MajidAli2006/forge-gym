import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Low-level auth persistence.
///
/// - Session (token + user JSON) → [FlutterSecureStorage] (sensitive).
/// - Onboarding flag + profile names → [SharedPreferences] (non-sensitive).
/// Knows nothing about domain entities — it stores strings.
abstract class AuthLocalDataSource {
  Future<void> saveSession({required String token, required String userJson});
  Future<({String token, String userJson})?> readSession();
  Future<void> clearSession();

  Future<void> setOnboardingCompleted();
  Future<bool> isOnboardingCompleted();

  Future<void> saveProfileName({required String email, required String name});
  Future<String?> getProfileName(String email);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._secureStorage, this._prefs);

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  static const String _sessionKey = 'forge.session';
  static const String _onboardingKey = 'forge.onboarding_completed';
  static const String _profileNamesKey = 'forge.profile_names';

  @override
  Future<void> saveSession({required String token, required String userJson}) {
    return _secureStorage.write(
      key: _sessionKey,
      value: jsonEncode({'token': token, 'user': userJson}),
    );
  }

  @override
  Future<({String token, String userJson})?> readSession() async {
    final raw = await _secureStorage.read(key: _sessionKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final token = decoded['token'] as String?;
      final userJson = decoded['user'] as String?;
      if (token == null || userJson == null) return null;
      return (token: token, userJson: userJson);
    } catch (_) {
      // Corrupt session — treat as signed out rather than crashing.
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> clearSession() => _secureStorage.delete(key: _sessionKey);

  @override
  Future<void> setOnboardingCompleted() => _prefs.setBool(_onboardingKey, true);

  @override
  Future<bool> isOnboardingCompleted() =>
      Future.value(_prefs.getBool(_onboardingKey) ?? false);

  @override
  Future<void> saveProfileName({
    required String email,
    required String name,
  }) async {
    final names = _decodeNames();
    names[email.toLowerCase()] = name;
    await _prefs.setString(_profileNamesKey, jsonEncode(names));
  }

  @override
  Future<String?> getProfileName(String email) async =>
      _decodeNames()[email.toLowerCase()];

  Map<String, String> _decodeNames() {
    final raw = _prefs.getString(_profileNamesKey);
    if (raw == null) return <String, String>{};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return <String, String>{};
    }
  }
}
