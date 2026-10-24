import 'package:flutter_test/flutter_test.dart';

import 'package:bakery_mobile/src/features/admin/audit/data/repositories/audit_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/coupons/data/repositories/coupon_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/membership/data/repositories/membership_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/product-attributes/data/repositories/product_attribute_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/settings/domain/models/settings_models.dart';

void main() {
  group('couponFromJson (fixtures pinned via curl 2026-10-24)', () {
    test('PERCENTAGE — value is a Decimal string', () {
      final coupon = couponFromJson({
        'id': 'c1',
        'code': 'SALE20',
        'sourceType': 'MANUAL',
        'type': 'PERCENTAGE',
        'value': '20',
        'minOrder': 100000,
        'maxDiscount': 50000,
        'usageLimit': 100,
        'perUserLimit': 1,
        'startAt': null,
        'endAt': '2026-12-31T00:00:00.000Z',
        'isActive': true,
      });
      expect(coupon.id, 'c1');
      expect(coupon.code, 'SALE20');
      expect(coupon.type, 'PERCENTAGE');
      expect(coupon.value, 20.0);
      expect(coupon.minOrder, 100000.0);
      expect(coupon.maxDiscount, 50000.0);
      expect(coupon.usageLimit, 100);
      expect(coupon.perUserLimit, 1);
      expect(coupon.isActive, isTrue);
      expect(coupon.endAt, DateTime.utc(2026, 12, 31));
    });

    test('FIXED — value string parsed, null limits tolerated', () {
      final coupon = couponFromJson({
        'id': 'c2',
        'code': 'GIAM25K',
        'type': 'FIXED',
        'value': '25000',
        'minOrder': null,
        'maxDiscount': null,
        'usageLimit': null,
        'perUserLimit': null,
        'isActive': false,
      });
      expect(coupon.type, 'FIXED');
      expect(coupon.value, 25000.0);
      expect(coupon.minOrder, isNull);
      expect(coupon.usageLimit, isNull);
      expect(coupon.isActive, isFalse);
    });
  });

  group('membershipFromJson (GET /api/admin/membership fixture)', () {
    test('levels + pointsPerOrder + totalMembers', () {
      final config = membershipFromJson({
        'levels': [
          {
            'level': 'SILVER',
            'label': 'Silver',
            'minPoints': 0,
            'discountPercent': 3,
            'memberCount': 6,
          },
          {
            'level': 'GOLD',
            'label': 'Gold',
            'minPoints': 300,
            'discountPercent': 7,
            'memberCount': 1,
          },
          {
            'level': 'PLATINUM',
            'label': 'Platinum',
            'minPoints': 900,
            'discountPercent': 12,
            'memberCount': 2,
          },
        ],
        'pointsPerOrder': 10000,
        'totalMembers': 9,
      });
      expect(config.levels, hasLength(3));
      expect(config.levels[1].level, 'GOLD');
      expect(config.levels[1].minPoints, 300);
      expect(config.levels[1].discountPercent, 7);
      expect(config.levels[1].memberCount, 1);
      expect(config.pointsPerOrder, 10000);
      expect(config.totalMembers, 9);
    });
  });

  group('auditRowFromJson (GET /api/admin/audit fixture)', () {
    test('nested actor map → actorName', () {
      final row = auditRowFromJson({
        'id': 'a1',
        'module': 'products',
        'entity': 'product',
        'entityId': 'e1',
        'summary': 'Tạo sản phẩm Bánh mì',
        'mutationType': 'CREATE',
        'actorUserId': 'u1',
        'actorRole': 'ADMIN',
        'actor': {'id': 'u1', 'name': 'Admin'},
        'createdAt': '2026-10-24T01:00:00.000Z',
      });
      expect(row.module, 'products');
      expect(row.entity, 'product');
      expect(row.summary, 'Tạo sản phẩm Bánh mì');
      expect(row.mutationType, 'CREATE');
      expect(row.actorName, 'Admin');
      expect(row.actorRole, 'ADMIN');
      expect(row.createdAt, DateTime.utc(2026, 10, 24, 1));
    });

    test('missing actor → null name, tolerant defaults', () {
      final row = auditRowFromJson({
        'id': 'a2',
        'module': 'settings',
        'createdAt': 'not-a-date',
      });
      expect(row.actorName, isNull);
      expect(row.summary, isEmpty);
      expect(row.createdAt.isBefore(DateTime.now()), isTrue);
    });
  });

  group('adminSettingsFromJson (GET /api/admin/settings fixture)', () {
    test('flat map, all values stringified, nulls dropped', () {
      final settings = adminSettingsFromJson({
        'store_name': 'Phương Loan Bakery',
        'store_email': 'hello@phuongloan.vn',
        'store_phone': 0255123456,
        'store_address': 'Quảng Ngãi',
        'opening_hours': '06:30 - 21:30',
        'null_key': null,
      });
      expect(settings['store_name'], 'Phương Loan Bakery');
      expect(settings['store_phone'], isNotEmpty);
      expect(settings['opening_hours'], '06:30 - 21:30');
      expect(settings.containsKey('null_key'), isFalse);
    });
  });

  group('catalogueAttributeFromJson (GET /api/admin/product-attributes)', () {
    test('values list with label fallback to value', () {
      final attribute = catalogueAttributeFromJson({
        'id': 'i1',
        'name': 'Mousse Cheesecake',
        'slug': 'mousse-cheesecake',
        'code': 'mousse_cheesecake',
        'type': 'MULTI_SELECT',
        'values': [
          {'id': 'v1', 'value': 'Passion', 'label': 'Passion'},
          {'id': 'v2', 'value': 'Chocolate'},
        ],
      });
      expect(attribute.name, 'Mousse Cheesecake');
      expect(attribute.code, 'mousse_cheesecake');
      expect(attribute.type, 'MULTI_SELECT');
      expect(attribute.values.map((v) => v.label), ['Passion', 'Chocolate']);
    });
  });

  group('deriveAttributeCode', () {
    test('latin name → upper snake', () {
      expect(deriveAttributeCode('Best Seller'), 'BEST_SELLER');
      expect(deriveAttributeCode('mousse cake'), 'MOUSSE_CAKE');
    });

    test('Vietnamese name → transliterated upper snake', () {
      expect(deriveAttributeCode('Hương Vị'), 'HUONG_VI');
    });

    test('no usable letters → timestamp fallback', () {
      expect(deriveAttributeCode('名前'), startsWith('ATTR_'));
      expect(deriveAttributeCode('🎂🎉'), startsWith('ATTR_'));
    });
  });
}
