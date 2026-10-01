import 'dart:convert';

import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';

/// Serializable form of [User] for secure-storage persistence.
/// Never leaves the data layer.
class UserDto {
  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.fitnessLevel,
    this.photoUrl,
    this.age,
    this.heightCm,
    this.weightKg,
  });

  final String id;
  final String name;
  final String email;
  final String fitnessLevel;
  final String? photoUrl;
  final int? age;
  final double? heightCm;
  final double? weightKg;

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    fitnessLevel: json['fitnessLevel'] as String? ?? 'beginner',
    photoUrl: json['photoUrl'] as String?,
    age: (json['age'] as num?)?.toInt(),
    heightCm: (json['heightCm'] as num?)?.toDouble(),
    weightKg: (json['weightKg'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'fitnessLevel': fitnessLevel,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (age != null) 'age': age,
    if (heightCm != null) 'heightCm': heightCm,
    if (weightKg != null) 'weightKg': weightKg,
  };

  factory UserDto.fromDomain(User user) => UserDto(
    id: user.id,
    name: user.name,
    email: user.email,
    fitnessLevel: user.fitnessLevel.name,
    photoUrl: user.photoUrl,
    age: user.age,
    heightCm: user.heightCm,
    weightKg: user.weightKg,
  );

  User toDomain() => User(
    id: id,
    name: name,
    email: email,
    fitnessLevel: FitnessLevelLabel.fromString(fitnessLevel),
    photoUrl: photoUrl,
    age: age,
    heightCm: heightCm,
    weightKg: weightKg,
  );

  static String encode(UserDto dto) => jsonEncode(dto.toJson());

  static UserDto decode(String raw) =>
      UserDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
