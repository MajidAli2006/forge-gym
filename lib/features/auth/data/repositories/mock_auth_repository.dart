import 'dart:async';

import 'package:forge_gym/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:forge_gym/features/auth/data/mappers/user_mapper.dart';
import 'package:forge_gym/features/auth/data/models/user_dto.dart';
import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';
import 'package:forge_gym/features/auth/domain/repositories/auth_repository.dart';

/// Development stand-in for the real backend auth.
///
/// MOCK BEHAVIOR (replace with `ApiAuthRepository` later — the domain
/// contract is unchanged):
/// - [signIn] accepts any valid-format email with a password of 6+ chars.
///   The display name comes from a previous sign-up, or from the email
///   prefix (e.g. `demo@forgegym.app` → "Demo").
/// - [signUp] stores the name locally, then signs the member in.
/// - [sendPasswordReset] always succeeds for a valid email (no email is sent).
/// - The session (token + user JSON) persists in secure storage, so a
///   restart restores the signed-in user. Passwords are never stored.
/// - ~600ms artificial latency simulates a network round trip.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._local);

  final AuthLocalDataSource _local;

  final StreamController<User?> _controller =
      StreamController<User?>.broadcast();

  User? _cachedUser;
  bool _initialized = false;

  static const Duration _latency = Duration(milliseconds: 600);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    _cachedUser = await _restoreUser();
  }

  Future<User?> _restoreUser() async {
    final session = await _local.readSession();
    if (session == null) return null;
    try {
      return UserMapper.toDomain(UserDto.decode(session.userJson));
    } catch (_) {
      await _local.clearSession();
      return null;
    }
  }

  Future<User> _persistSession(User user) async {
    final token = 'mock-token-${DateTime.now().microsecondsSinceEpoch}';
    await _local.saveSession(
      token: token,
      userJson: UserDto.encode(UserMapper.toDto(user)),
    );
    _cachedUser = user;
    _controller.add(user);
    return user;
  }

  String _displayNameFor(String email) =>
      email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ').trim();

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  Stream<User?> watchUser() async* {
    await _ensureInitialized();
    yield _cachedUser;
    yield* _controller.stream;
  }

  @override
  Future<User?> currentUser() async {
    await _ensureInitialized();
    return _cachedUser;
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    await _ensureInitialized();
    await Future<void>.delayed(_latency);
    final savedName = await _local.getProfileName(email);
    final user = User(
      id: 'mock-${email.toLowerCase()}',
      name: savedName ?? _titleCase(_displayNameFor(email)),
      email: email,
      fitnessLevel: FitnessLevel.beginner,
    );
    return _persistSession(user);
  }

  @override
  Future<User> signUp({
    required String name,
    required String email,
    required String password,
    required FitnessLevel fitnessLevel,
  }) async {
    await _ensureInitialized();
    await Future<void>.delayed(_latency);
    await _local.saveProfileName(email: email, name: name);
    final user = User(
      id: 'mock-${email.toLowerCase()}',
      name: name,
      email: email,
      fitnessLevel: fitnessLevel,
    );
    return _persistSession(user);
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _local.clearSession();
    _cachedUser = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    await Future<void>.delayed(_latency);
    // Mock: nothing to send. The real implementation calls the backend here.
  }

  @override
  Future<User> updateProfile(User user) async {
    await _ensureInitialized();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _local.saveProfileName(email: user.email, name: user.name);
    return _persistSession(user);
  }

  @override
  Future<bool> isOnboardingCompleted() => _local.isOnboardingCompleted();

  @override
  Future<void> completeOnboarding() => _local.setOnboardingCompleted();
}
