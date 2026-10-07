import 'package:bakery_mobile/src/features/addresses/data/dtos/address_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture mirrors the web payload produced by the address routes
/// (`GET /api/addresses` → `{ success, data: { addresses: [...] } }`).
/// `ApiClient.get` unwraps `data`, so the service feeds each entry of
/// `data['addresses']` straight into `AddressDto.fromJson`.
Map<String, dynamic> get _fullAddress => {
  'id': 'addr-1',
  'userId': 'user-1',
  'fullName': 'Nguyễn Văn A',
  'phone': '0901234567',
  'street': '12 Nguyễn Trãi',
  'ward': 'Phường Bến Nghé',
  'district': 'Quận 1',
  'province': 'TP. Hồ Chí Minh',
  'isDefault': true,
  'createdAt': '2026-10-03T01:02:03.000Z',
  'someFutureField': 42,
};

void main() {
  group('AddressDto.fromJson', () {
    test('parses full server payload', () {
      final dto = AddressDto.fromJson(_fullAddress);
      final address = dto.toDomain();

      expect(address.id, 'addr-1');
      expect(address.userId, 'user-1');
      expect(address.fullName, 'Nguyễn Văn A');
      expect(address.phone, '0901234567');
      expect(address.street, '12 Nguyễn Trãi');
      expect(address.ward, 'Phường Bến Nghé');
      expect(address.district, 'Quận 1');
      expect(address.province, 'TP. Hồ Chí Minh');
      expect(address.isDefault, isTrue);
      expect(address.createdAt, DateTime.utc(2026, 10, 3, 1, 2, 3));
    });

    test('joins street, ward, district, province into one line', () {
      final address = AddressDto.fromJson(_fullAddress).toDomain();

      expect(
        address.addressLine,
        '12 Nguyễn Trãi, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh',
      );
    });

    test('survives missing optional fields', () {
      final dto = AddressDto.fromJson({
        'id': 'addr-2',
        'fullName': 'Trần Thị B',
        'phone': '0987654321',
        'street': '9 Lê Lợi',
        'ward': 'Phường Bến Thành',
        'district': 'Quận 1',
        'province': 'TP. Hồ Chí Minh',
        'isDefault': null,
        'createdAt': null,
      });
      final address = dto.toDomain();

      expect(address.id, 'addr-2');
      expect(address.userId, isEmpty);
      expect(address.isDefault, isFalse);
      expect(
        address.createdAt,
        isNotNull,
        reason: 'missing createdAt falls back to now instead of crashing',
      );
      expect(address.addressLine, '9 Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh');
    });

    test('list parsing via fromJsonList keeps order', () {
      final dtos = AddressDto.fromJsonList([
        _fullAddress,
        {
          'id': 'addr-2',
          'userId': 'user-1',
          'fullName': 'Trần Thị B',
          'phone': '0987654321',
          'street': '9 Lê Lợi',
          'ward': 'Phường Bến Thành',
          'district': 'Quận 1',
          'province': 'TP. Hồ Chí Minh',
          'isDefault': false,
          'createdAt': '2026-10-04T01:02:03.000Z',
        },
      ]);

      expect(dtos, hasLength(2));
      expect(dtos[0].id, 'addr-1');
      expect(dtos[0].isDefault, isTrue);
      expect(dtos[1].id, 'addr-2');
      expect(dtos[1].isDefault, isFalse);
    });
  });
}
