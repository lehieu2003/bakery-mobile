class Address {
  const Address({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.street,
    required this.ward,
    required this.district,
    required this.province,
    this.isDefault = false,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String street;
  final String ward;
  final String district;
  final String province;
  final bool isDefault;
  final DateTime createdAt;

  /// One-line text used to fill the checkout address field, mirroring the
  /// web app: "street, ward, district, province".
  String get addressLine => [street, ward, district, province]
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(', ');
}
