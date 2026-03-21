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
    final data = json['data'];
    final dataMap = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final userMap =
        (json['user'] is Map<String, dynamic>)
            ? json['user'] as Map<String, dynamic>
            : (dataMap['user'] is Map<String, dynamic>
                  ? dataMap['user'] as Map<String, dynamic>
                  : const <String, dynamic>{});
    final token =
        json['token']?.toString() ??
        json['accessToken']?.toString() ??
        dataMap['token']?.toString() ??
        dataMap['accessToken']?.toString() ??
        '';

    return AuthSessionDto(
      user: UserDto.fromJson(userMap),
      token: token,
    );
  }
}
