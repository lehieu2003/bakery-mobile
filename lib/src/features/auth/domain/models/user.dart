class User {
  const User({
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

  bool get isCustomer => role == 'CUSTOMER';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
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
}
