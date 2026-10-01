import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/auth/presentation/validators/auth_validators.dart';

void main() {
  group('AuthValidators.validateEmail', () {
    test('accepts a well-formed email', () {
      expect(AuthValidators.validateEmail('alex@example.com'), isNull);
    });

    test('rejects empty email', () {
      expect(AuthValidators.validateEmail(''), isNotNull);
      expect(AuthValidators.validateEmail(null), isNotNull);
    });

    test('rejects malformed emails', () {
      expect(AuthValidators.validateEmail('not-an-email'), isNotNull);
      expect(AuthValidators.validateEmail('a@b'), isNotNull);
      expect(AuthValidators.validateEmail('a b@c.com'), isNotNull);
    });

    test('trims surrounding whitespace', () {
      expect(AuthValidators.validateEmail('  alex@example.com  '), isNull);
    });
  });

  group('AuthValidators.validatePassword', () {
    test('accepts 6+ character passwords', () {
      expect(AuthValidators.validatePassword('123456'), isNull);
      expect(AuthValidators.validatePassword('password123'), isNull);
    });

    test('rejects short or empty passwords', () {
      expect(AuthValidators.validatePassword('12345'), isNotNull);
      expect(AuthValidators.validatePassword(''), isNotNull);
      expect(AuthValidators.validatePassword(null), isNotNull);
    });
  });

  group('AuthValidators.validateName', () {
    test('accepts names of 2+ characters', () {
      expect(AuthValidators.validateName('Alex'), isNull);
      expect(AuthValidators.validateName('Al'), isNull);
    });

    test('rejects blank or single-character names', () {
      expect(AuthValidators.validateName(''), isNotNull);
      expect(AuthValidators.validateName('   '), isNotNull);
      expect(AuthValidators.validateName('A'), isNotNull);
      expect(AuthValidators.validateName(null), isNotNull);
    });
  });
}
