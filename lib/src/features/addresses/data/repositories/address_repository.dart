import 'package:bakery_mobile/src/features/addresses/data/datasources/address_api_service.dart';
import 'package:bakery_mobile/src/features/addresses/data/dtos/address_dto.dart';
import 'package:bakery_mobile/src/features/addresses/domain/models/address.dart';

class AddressRepository {
  AddressRepository(this._addressApiService);

  final AddressApiService _addressApiService;

  Future<List<Address>> getAddresses() async {
    final raw = await _addressApiService.getAddresses();
    return AddressDto.fromJsonList(raw).map((item) => item.toDomain()).toList();
  }

  Future<Address> createAddress({
    required String fullName,
    required String phone,
    required String street,
    required String ward,
    required String district,
    required String province,
    bool isDefault = false,
  }) async {
    final raw = await _addressApiService.createAddress(
      fullName: fullName,
      phone: phone,
      street: street,
      ward: ward,
      district: district,
      province: province,
      isDefault: isDefault,
    );
    return AddressDto.fromJson(raw).toDomain();
  }

  Future<Address> updateAddress(
    String id, {
    String? fullName,
    String? phone,
    String? street,
    String? ward,
    String? district,
    String? province,
    bool? isDefault,
  }) async {
    final raw = await _addressApiService.updateAddress(
      id,
      fullName: fullName,
      phone: phone,
      street: street,
      ward: ward,
      district: district,
      province: province,
      isDefault: isDefault,
    );
    return AddressDto.fromJson(raw).toDomain();
  }

  Future<void> deleteAddress(String id) {
    return _addressApiService.deleteAddress(id);
  }
}
