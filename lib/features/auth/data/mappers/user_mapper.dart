import 'package:forge_gym/features/auth/data/models/user_dto.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';

/// Converts between the persistence [UserDto] and the domain [User].
/// UI code never sees a DTO.
abstract final class UserMapper {
  static User toDomain(UserDto dto) => dto.toDomain();

  static UserDto toDto(User user) => UserDto.fromDomain(user);
}
