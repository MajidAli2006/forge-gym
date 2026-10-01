import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/auth/data/mappers/user_mapper.dart';
import 'package:forge_gym/features/auth/data/models/user_dto.dart';
import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';

void main() {
  const user = User(
    id: 'mock-alex@example.com',
    name: 'Alex Morgan',
    email: 'alex@example.com',
    fitnessLevel: FitnessLevel.advanced,
    age: 30,
    heightCm: 180.5,
    weightKg: 82.3,
  );

  group('UserMapper', () {
    test('round-trips entity -> dto -> entity without loss', () {
      final dto = UserMapper.toDto(user);
      final decoded = UserDto.decode(UserDto.encode(dto));
      final back = UserMapper.toDomain(decoded);
      expect(back, equals(user));
    });

    test('serializes fitnessLevel as its enum name', () {
      final dto = UserMapper.toDto(user);
      expect(dto.toJson()['fitnessLevel'], 'advanced');
    });

    test('falls back to beginner for unknown fitnessLevel strings', () {
      const dto = UserDto(
        id: '1',
        name: 'A',
        email: 'a@b.com',
        fitnessLevel: 'superhuman',
      );
      expect(UserMapper.toDomain(dto).fitnessLevel, FitnessLevel.beginner);
    });

    test('omits null optional fields from JSON', () {
      const minimal = User(
        id: '1',
        name: 'A B',
        email: 'a@b.com',
        fitnessLevel: FitnessLevel.beginner,
      );
      final json = UserMapper.toDto(minimal).toJson();
      expect(json.containsKey('photoUrl'), isFalse);
      expect(json.containsKey('age'), isFalse);
    });
  });
}
