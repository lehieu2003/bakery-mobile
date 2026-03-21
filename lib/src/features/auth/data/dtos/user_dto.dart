import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.memberLevel,
    this.points,
  });

  final String id;
  final String email;
  final String role;
  final String? name;
  final String? memberLevel;
  final int? points;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      name: json['name']?.toString(),
      memberLevel: json['memberLevel']?.toString(),
      points: json['points'] is int
          ? json['points'] as int
          : int.tryParse('${json['points'] ?? ''}'),
    );
  }

  User toDomain() {
    return User(
      id: id,
      email: email,
      role: role,
      name: name,
      memberLevel: memberLevel,
      points: points,
    );
  }
}

class AuthSessionDto {
  const AuthSessionDto({required this.user, required this.token});

  final UserDto user;
  final String token;

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    return AuthSessionDto(
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>? ?? const {}),
      token: json['token']?.toString() ?? '',
    );
  }
}
