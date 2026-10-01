import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:forge_gym/core/errors/failures.dart';
import 'package:forge_gym/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:forge_gym/features/auth/data/mappers/user_mapper.dart';
import 'package:forge_gym/features/auth/data/models/user_dto.dart';
import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';
import 'package:forge_gym/features/auth/domain/repositories/auth_repository.dart';

/// Real accounts on Firebase Authentication (email + password).
///
/// Firebase owns identity (uid, email, display name, password reset).
/// The member's training profile (level, age, height, weight) is kept in
/// the same local session store the mock used, keyed by uid, so switching
/// to a Firestore-backed profile later only touches this class.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._local);

  final fb.FirebaseAuth _auth;
  final AuthLocalDataSource _local;

  final StreamController<User?> _controller =
      StreamController<User?>.broadcast();
  User? _cachedUser;
  bool _initialized = false;
  StreamSubscription<fb.User?>? _authSubscription;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    _cachedUser = await _compose(_auth.currentUser);
    _authSubscription = _auth.authStateChanges().listen((fbUser) async {
      // Sign-out from another device or token revocation lands here.
      if (fbUser == null && _cachedUser != null) {
        _cachedUser = null;
        await _local.clearSession();
        _controller.add(null);
      }
    });
  }

  /// Merges Firebase identity with the locally stored training profile.
  Future<User?> _compose(fb.User? fbUser) async {
    if (fbUser == null) return null;
    final session = await _local.readSession();
    User? stored;
    if (session != null) {
      try {
        stored = UserMapper.toDomain(UserDto.decode(session.userJson));
      } catch (_) {
        stored = null;
      }
    }
    final email = fbUser.email ?? stored?.email ?? '';
    final name = fbUser.displayName?.trim().isNotEmpty == true
        ? fbUser.displayName!.trim()
        : (stored?.name ?? _displayNameFor(email));
    final base = stored != null && stored.id == fbUser.uid
        ? stored
        : User(
            id: fbUser.uid,
            name: name,
            email: email,
            fitnessLevel: FitnessLevel.beginner,
          );
    return base.copyWith(
      id: fbUser.uid,
      name: name,
      email: email,
      photoUrl: fbUser.photoURL ?? base.photoUrl,
    );
  }

  Future<User> _persist(User user) async {
    final token = await _auth.currentUser?.getIdToken() ?? 'firebase';
    await _local.saveSession(
      token: token,
      userJson: UserDto.encode(UserMapper.toDto(user)),
    );
    _cachedUser = user;
    _controller.add(user);
    return user;
  }

  static String _displayNameFor(String email) {
    final raw = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
    return raw
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
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = await _compose(credential.user);
      if (user == null) throw const UnknownFailure();
      return _persist(user);
    } on fb.FirebaseAuthException catch (error) {
      throw _mapAuthError(error);
    }
  }

  @override
  Future<User> signUp({
    required String name,
    required String email,
    required String password,
    required FitnessLevel fitnessLevel,
  }) async {
    await _ensureInitialized();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      final fbUser = credential.user;
      if (fbUser == null) throw const UnknownFailure();
      return _persist(
        User(
          id: fbUser.uid,
          name: name.trim(),
          email: fbUser.email ?? email.trim(),
          fitnessLevel: fitnessLevel,
        ),
      );
    } on fb.FirebaseAuthException catch (error) {
      throw _mapAuthError(error);
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await _auth.signOut();
    await _local.clearSession();
    _cachedUser = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (error) {
      // Don't reveal whether an account exists; only surface real faults.
      if (error.code == 'user-not-found' || error.code == 'invalid-email') {
        return;
      }
      throw _mapAuthError(error);
    }
  }

  @override
  Future<User> updateProfile(User user) async {
    await _ensureInitialized();
    final fbUser = _auth.currentUser;
    if (fbUser != null && fbUser.displayName != user.name) {
      try {
        await fbUser.updateDisplayName(user.name);
      } on fb.FirebaseAuthException catch (error) {
        throw _mapAuthError(error);
      }
    }
    return _persist(user);
  }

  @override
  Future<bool> isOnboardingCompleted() => _local.isOnboardingCompleted();

  @override
  Future<void> completeOnboarding() => _local.setOnboardingCompleted();

  /// Firebase error codes → the app's user-facing [Failure]s.
  static Failure _mapAuthError(fb.FirebaseAuthException error) {
    // Email/password sign-in has not been switched on in the Firebase
    // console yet (Authentication → Get started → Email/Password).
    if (error.message?.contains('CONFIGURATION_NOT_FOUND') ?? false) {
      return const ServerFailure(
        'Sign-in is not switched on for this app yet. Please contact the gym.',
      );
    }
    return switch (error.code) {
      'invalid-email' => const ValidationFailure(
        'That email address doesn\'t look right.',
      ),
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' => const ValidationFailure(
        'Incorrect email or password.',
      ),
      'email-already-in-use' => const ValidationFailure(
        'An account already exists for that email. Try signing in.',
      ),
      'weak-password' => const ValidationFailure(
        'Choose a stronger password (at least 6 characters).',
      ),
      'user-disabled' => const UnauthorizedFailure(
        'This account has been disabled. Contact the gym for help.',
      ),
      'too-many-requests' => const ServerFailure(
        'Too many attempts. Please wait a moment and try again.',
      ),
      'network-request-failed' => const NetworkFailure(),
      'operation-not-allowed' => const ServerFailure(
        'Email sign-in is not enabled yet. Contact the gym.',
      ),
      _ => UnknownFailure(error.message ?? 'Something went wrong.'),
    };
  }

  void dispose() {
    _authSubscription?.cancel();
    _controller.close();
  }
}
