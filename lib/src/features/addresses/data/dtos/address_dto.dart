import 'package:bakery_mobile/src/features/addresses/domain/models/address.dart';

class AddressDto {
  const AddressDto({
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

  factory AddressDto.fromJson(Map<String, dynamic> json) {
    return AddressDto(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      street: (json['street'] ?? '').toString(),
      ward: (json['ward'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      province: (json['province'] ?? '').toString(),
      isDefault: json['isDefault'] == true,
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  static List<AddressDto> fromJsonList(List<dynamic> raw) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AddressDto.fromJson)
        .toList();
  }

  Address toDomain() => Address(
    id: id,
    userId: userId,
    fullName: fullName,
    phone: phone,
    street: street,
    ward: ward,
    district: district,
    province: province,
    isDefault: isDefault,
    createdAt: createdAt,
  );
}
