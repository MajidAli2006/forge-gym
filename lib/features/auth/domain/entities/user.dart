import 'package:equatable/equatable.dart';
import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';

/// Authenticated gym member.
///
/// Pure domain object — no JSON, no Flutter. Persistence details live in
/// the data layer's [UserDto].
class User extends Equatable {
  const User({
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
  final FitnessLevel fitnessLevel;
  final String? photoUrl;
  final int? age;
  final double? heightCm;
  final double? weightKg;

  User copyWith({
    String? id,
    String? name,
    String? email,
    FitnessLevel? fitnessLevel,
    String? photoUrl,
    int? age,
    double? heightCm,
    double? weightKg,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    fitnessLevel,
    photoUrl,
    age,
    heightCm,
    weightKg,
  ];
}
