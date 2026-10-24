import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/audit/data/datasources/audit_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/audit/data/repositories/audit_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/coupons/data/datasources/coupon_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/coupons/data/repositories/coupon_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/coupons/domain/models/coupon_models.dart';
import 'package:bakery_mobile/src/features/admin/membership/data/datasources/membership_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/membership/data/repositories/membership_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/membership/domain/models/membership_models.dart';
import 'package:bakery_mobile/src/features/admin/product-attributes/data/datasources/product_attribute_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/product-attributes/data/repositories/product_attribute_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/product-attributes/domain/models/product_attribute_models.dart';
import 'package:bakery_mobile/src/features/admin/settings/data/datasources/settings_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/settings/data/repositories/settings_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/settings/domain/models/settings_models.dart';
import 'package:bakery_mobile/src/features/admin/audit/presentation/controllers/audit_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/coupons/presentation/controllers/coupons_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/membership/presentation/controllers/membership_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/product-attributes/presentation/controllers/product_attributes_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/settings/presentation/controllers/settings_admin_view_model.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ApiException _unauthorized() => ApiException('Unauthorized', statusCode: 401);

class _FakeAuthViewModel extends AuthViewModel {
  int logoutCalls = 0;

  @override
  AuthState build() => const AuthState(
    user: User(id: 'a', email: 'a@b.c', name: 'A', role: 'ADMIN'),
  );

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

// ---- Coupons ----

class _FakeCouponRepo extends CouponAdminRepository {
  _FakeCouponRepo() : super(CouponAdminApiService(_stubClient));

  static final _stubClient = ApiClient(
    baseUrl: 'http://localhost:1',
    tokenProvider: () async => null,
  );

  final created = <Map<String, dynamic>>[];
  final deletedIds = <String>[];
  final toggles = <Map<String, dynamic>>[];
  Object? createError;

  @override
  Future<List<AdminCoupon>> getCoupons() async => [
    couponFromJson({
      'id': 'c-1',
      'code': 'SALE20',
      'type': 'PERCENTAGE',
      'value': '20',
      'isActive': true,
    }),
  ];

  @override
  Future<void> createCoupon(Map<String, dynamic> body) async {
    final thrown = createError;
    if (thrown != null) throw thrown;
    created.add(body);
  }

  @override
  Future<void> deleteCoupon(String id) async {
    deletedIds.add(id);
  }

  @override
  Future<void> setCouponActive(String id, {required bool isActive}) async {
    toggles.add({'id': id, 'isActive': isActive});
  }
}

// ---- Product attributes ----

class _FakeAttributeRepo extends ProductAttributeAdminRepository {
  _FakeAttributeRepo() : super(ProductAttributeAdminApiService(_stubClient));

  static final _stubClient = ApiClient(
    baseUrl: 'http://localhost:1',
    tokenProvider: () async => null,
  );

  final created = <Map<String, dynamic>>[];
  final removedIds = <String>[];

  @override
  Future<List<AdminCatalogueAttribute>> getAttributes() async => [
    catalogueAttributeFromJson({
      'id': 'a-1',
      'name': 'Màu kem',
      'code': 'MAU_KEM',
      'type': 'MULTI_SELECT',
      'values': [
        {'id': 'v-1', 'label': 'Chocolate'},
      ],
    }),
  ];

  @override
  Future<AdminCatalogueAttribute> createAttribute({
    required String name,
    required String type,
    List<String> valueLabels = const [],
  }) async {
    created.add({
      'name': name,
      'type': type,
      'values': [
        for (final label in valueLabels)
          if (label.trim().isNotEmpty) {'label': label.trim()},
      ],
    });
    return AdminCatalogueAttribute(
      id: 'new-1',
      name: name,
      code: 'NEW',
      type: type,
      values: [
        for (final label in valueLabels)
          AdminCatalogueValue(id: label, label: label),
      ],
    );
  }

  @override
  Future<AdminCatalogueAttribute> updateAttribute({
    required String id,
    String? name,
    String? type,
    List<String>? valueLabels,
  }) async => AdminCatalogueAttribute(
    id: id,
    name: name ?? '',
    code: 'UPDATED',
    type: type ?? 'SELECT',
    values: const [],
  );

  @override
  Future<void> deleteAttribute(String id) async {
    removedIds.add(id);
  }
}

// ---- Membership ----

class _FakeMembershipRepo extends MembershipAdminRepository {
  _FakeMembershipRepo() : super(MembershipAdminApiService(_stubClient));

  static final _stubClient = ApiClient(
    baseUrl: 'http://localhost:1',
    tokenProvider: () async => null,
  );

  Map<String, dynamic>? lastPut;

  @override
  Future<MembershipConfig> getMembership() async => MembershipConfig(
    pointsPerOrder: 10000,
    totalMembers: 7,
    levels: [
      const MembershipLevelConfig(
        level: 'SILVER',
        label: 'Silver',
        minPoints: 0,
        discountPercent: 3,
        memberCount: 6,
      ),
      const MembershipLevelConfig(
        level: 'GOLD',
        label: 'Gold',
        minPoints: 300,
        discountPercent: 7,
        memberCount: 1,
      ),
    ],
  );

  @override
  Future<void> putMembership(Map<String, dynamic> body) async {
    lastPut = body;
  }
}

// ---- Audit ----

class _FakeAuditRepo extends AuditAdminRepository {
  _FakeAuditRepo() : super(AuditAdminApiService(_stubClient));

  static final _stubClient = ApiClient(
    baseUrl: 'http://localhost:1',
    tokenProvider: () async => null,
  );

  final requestedPages = <int>[];
  Object? error;

  @override
  Future<AuditLogPage> getAudit({int page = 1, int limit = 20}) async {
    requestedPages.add(page);
    final thrown = error;
    if (thrown != null) throw thrown;
    if (page == 1) {
      return AuditLogPage(
        items: [
          auditRowFromJson({
            'id': 'log-1',
            'module': 'products',
            'entity': 'product',
            'summary': 'Tạo sản phẩm',
            'mutationType': 'CREATE',
            'actor': {'name': 'Admin'},
            'actorRole': 'ADMIN',
            'createdAt': '2026-10-24T01:00:00.000Z',
          }),
        ],
        totalPages: 2,
      );
    }
    return AuditLogPage(
      items: [
        auditRowFromJson({
          'id': 'log-2',
          'module': 'settings',
          'entity': 'settings',
          'summary': 'Cập nhật cài đặt',
          'mutationType': 'UPDATE',
          'actorRole': 'ADMIN',
          'createdAt': '2026-10-24T02:00:00.000Z',
        }),
      ],
      totalPages: 2,
    );
  }
}

// ---- Settings ----

class _FakeSettingsRepo extends SettingsAdminRepository {
  _FakeSettingsRepo() : super(SettingsAdminApiService(_stubClient));

  static final _stubClient = ApiClient(
    baseUrl: 'http://localhost:1',
    tokenProvider: () async => null,
  );

  Map<String, dynamic>? lastPut;
  Object? error;

  @override
  Future<AdminSettings> getSettings() async => {
    'store_name': 'Phương Loan Bakery',
    'store_email': 'hello@phuongloan.vn',
  };

  @override
  Future<void> putSettings(Map<String, dynamic> body) async {
    final thrown = error;
    if (thrown != null) throw thrown;
    lastPut = body;
  }
}

void main() {
  late _FakeAuthViewModel auth;

  setUp(() {
    auth = _FakeAuthViewModel();
  });

  ProviderContainer makeContainer(List<Override> overrides) {
    final c = ProviderContainer(
      overrides: [...overrides, authViewModelProvider.overrideWith(() => auth)],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('CouponsAdminViewModel', () {
    late _FakeCouponRepo repo;
    setUp(() => repo = _FakeCouponRepo());

    CouponsAdminViewModel vm(ProviderContainer c) =>
        c.read(couponsAdminViewModelProvider.notifier);

    test('load() parses Decimal-string value', () async {
      final c = makeContainer([
        couponAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      await vm(c).load();

      expect(c.read(couponsAdminViewModelProvider).items, hasLength(1));
      expect(c.read(couponsAdminViewModelProvider).items.first.value, 20.0);
    });

    test(
      'create() rejects invalid code and bad date range client-side',
      () async {
        final c = makeContainer([
          couponAdminRepositoryProvider.overrideWithValue(repo),
        ]);
        final okCode = await vm(c).create(
          code: 'ab',
          type: 'PERCENTAGE',
          value: 10,
          startAt: DateTime(2026),
          endAt: DateTime(2027),
        );
        expect(okCode, isFalse);
        expect(repo.created, isEmpty);

        final okRange = await vm(c).create(
          code: 'SALE10',
          type: 'PERCENTAGE',
          value: 10,
          startAt: DateTime(2027),
          endAt: DateTime(2026),
        );
        expect(okRange, isFalse);
        expect(repo.created, isEmpty);
      },
    );

    test('create() sends uppercased code + ISO dates and reloads', () async {
      final c = makeContainer([
        couponAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      final ok = await vm(c).create(
        code: ' sale30 ',
        type: 'FIXED',
        value: 30000,
        startAt: DateTime(2026, 1, 1),
        endAt: DateTime(2026, 12, 31),
        minOrder: 100000,
      );

      expect(ok, isTrue);
      expect(repo.created.single['code'], 'SALE30');
      expect(repo.created.single['type'], 'FIXED');
      expect(repo.created.single['startAt'], contains('2026-01-01'));
      expect(repo.created.single['minOrder'], 100000);
      // Reloaded after create.
      expect(c.read(couponsAdminViewModelProvider).items, isNotEmpty);
    });

    test('create() surfaces server 400 and logs out on 401', () async {
      repo.createError = ApiException('bad', statusCode: 400);
      final c = makeContainer([
        couponAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      final ok = await vm(c).create(
        code: 'SALE30',
        type: 'FIXED',
        value: 30000,
        startAt: DateTime(2026),
        endAt: DateTime(2027),
      );
      expect(ok, isFalse);
      expect(c.read(couponsAdminViewModelProvider).error, isNotNull);

      repo.createError = _unauthorized();
      final ok401 = await vm(c).create(
        code: 'SALE30',
        type: 'FIXED',
        value: 30000,
        startAt: DateTime(2026),
        endAt: DateTime(2027),
      );
      expect(ok401, isFalse);
      expect(auth.logoutCalls, 1);
    });

    test('setActive() toggles via PUT and updates local state', () async {
      final c = makeContainer([
        couponAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      await vm(c).load();

      final ok = await vm(c).setActive('c-1', isActive: false);

      expect(ok, isTrue);
      expect(repo.toggles.single, {'id': 'c-1', 'isActive': false});
      expect(
        c.read(couponsAdminViewModelProvider).items.first.isActive,
        isFalse,
      );
    });

    test('remove() deletes and drops the row locally', () async {
      final c = makeContainer([
        couponAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      await vm(c).load();

      final ok = await vm(c).remove('c-1');

      expect(ok, isTrue);
      expect(repo.deletedIds, ['c-1']);
      expect(c.read(couponsAdminViewModelProvider).items, isEmpty);
    });
  });

  group('ProductAttributesAdminViewModel', () {
    late _FakeAttributeRepo repo;
    setUp(() => repo = _FakeAttributeRepo());

    ProductAttributesAdminViewModel vm(ProviderContainer c) =>
        c.read(productAttributesAdminViewModelProvider.notifier);

    test('load() parses catalogue with values', () async {
      final c = makeContainer([
        productAttributeAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      await vm(c).load();

      final items = c.read(productAttributesAdminViewModelProvider).items;
      expect(items, hasLength(1));
      expect(items.first.name, 'Màu kem');
      expect(items.first.values.single.label, 'Chocolate');
    });

    test('create() rejects empty name, derives code server-side', () async {
      final c = makeContainer([
        productAttributeAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      final bad = await vm(c).create(name: '   ', type: 'MULTI_SELECT');
      expect(bad, isFalse);
      expect(repo.created, isEmpty);

      final ok = await vm(c).create(
        name: 'Hương vị',
        type: 'MULTI_SELECT',
        valueLabels: ['Chocolate', '  '],
      );
      expect(ok, isTrue);
      expect(repo.created.single['name'], 'Hương vị');
      expect(repo.created.single['values'], [
        {'label': 'Chocolate'},
      ]);
    });

    test('update() sends name + values then reloads', () async {
      final c = makeContainer([
        productAttributeAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      await vm(c).load();

      final ok = await vm(
        c,
      ).update(id: 'a-1', name: 'Màu kem mới', valueLabels: ['Vanilla']);

      expect(ok, isTrue);
      expect(c.read(productAttributesAdminViewModelProvider).items, isNotEmpty);
    });

    test('remove() deletes and drops locally', () async {
      final c = makeContainer([
        productAttributeAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      await vm(c).load();

      final ok = await vm(c).remove('a-1');

      expect(ok, isTrue);
      expect(repo.removedIds, ['a-1']);
      expect(c.read(productAttributesAdminViewModelProvider).items, isEmpty);
    });
  });

  group('MembershipAdminViewModel', () {
    late _FakeMembershipRepo repo;
    setUp(() => repo = _FakeMembershipRepo());

    MembershipAdminViewModel vm(ProviderContainer c) =>
        c.read(membershipAdminViewModelProvider.notifier);

    test('load() parses levels + pointsPerOrder', () async {
      final c = makeContainer([
        membershipAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      await vm(c).load();

      final config = c.read(membershipAdminViewModelProvider).config!;
      expect(config.levels, hasLength(2));
      expect(config.pointsPerOrder, 10000);
    });

    test(
      'updateConfig(tier) PUTs full levels with the new minPoints',
      () async {
        final c = makeContainer([
          membershipAdminRepositoryProvider.overrideWithValue(repo),
        ]);
        await vm(c).load();

        final ok = await vm(c).updateConfig(tierKey: 'GOLD', value: 500);

        expect(ok, isTrue);
        expect(repo.lastPut, {
          'levels': [
            {'key': 'SILVER', 'minPoints': 0},
            {'key': 'GOLD', 'minPoints': 500},
          ],
          'pointsPerOrder': 10000,
        });
      },
    );

    test('updateConfig(null tier) PUTs new pointsPerOrder only', () async {
      final c = makeContainer([
        membershipAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      await vm(c).load();

      final ok = await vm(c).updateConfig(value: 20000);

      expect(ok, isTrue);
      expect(repo.lastPut!['pointsPerOrder'], 20000);
      expect((repo.lastPut!['levels'] as List)[1], {
        'key': 'GOLD',
        'minPoints': 300,
      });
    });

    test('negative value rejected without PUT', () async {
      final c = makeContainer([
        membershipAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      await vm(c).load();

      final ok = await vm(c).updateConfig(value: -1);

      expect(ok, isFalse);
      expect(repo.lastPut, isNull);
    });
  });

  group('AuditAdminViewModel', () {
    late _FakeAuditRepo repo;
    setUp(() => repo = _FakeAuditRepo());

    AuditAdminViewModel vm(ProviderContainer c) =>
        c.read(auditAdminViewModelProvider.notifier);

    test('load() page 1 parses logs + totalPages', () async {
      final c = makeContainer([
        auditAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      await vm(c).load();

      final state = c.read(auditAdminViewModelProvider);
      expect(state.items, hasLength(1));
      expect(state.items.first.actorName, 'Admin');
      expect(state.totalPages, 2);
      expect(state.canLoadMore, isTrue);
    });

    test('loadMore() appends page 2 rows', () async {
      final c = makeContainer([
        auditAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      await vm(c).load();
      await vm(c).loadMore();

      final state = c.read(auditAdminViewModelProvider);
      expect(state.items, hasLength(2));
      expect(state.page, 2);
      expect(state.canLoadMore, isFalse);
      expect(repo.requestedPages, [1, 2]);
    });

    test('401 on load triggers logout', () async {
      repo.error = _unauthorized();
      final c = makeContainer([
        auditAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      await vm(c).load();

      expect(auth.logoutCalls, 1);
    });
  });

  group('SettingsAdminViewModel', () {
    late _FakeSettingsRepo repo;
    setUp(() => repo = _FakeSettingsRepo());

    SettingsAdminViewModel vm(ProviderContainer c) =>
        c.read(settingsAdminViewModelProvider.notifier);

    test('load() parses flat settings map', () async {
      final c = makeContainer([
        settingsAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      await vm(c).load();

      expect(
        c.read(settingsAdminViewModelProvider).values['store_name'],
        'Phương Loan Bakery',
      );
    });

    test('save() PUTs the full map and mirrors it into state', () async {
      final c = makeContainer([
        settingsAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      await vm(c).load();

      final ok = await vm(c).save({
        'store_name': 'Phương Loan Bakery',
        'store_email': 'hello@phuongloan.vn',
        'store_phone': '0255',
        'store_address': 'Quảng Ngãi',
        'opening_hours': '06:30 - 21:30',
      });

      expect(ok, isTrue);
      expect(repo.lastPut!['opening_hours'], '06:30 - 21:30');
      expect(
        c.read(settingsAdminViewModelProvider).values['store_phone'],
        '0255',
      );
    });

    test('save() surfaces server error', () async {
      repo.error = ApiException('bad', statusCode: 400);
      final c = makeContainer([
        settingsAdminRepositoryProvider.overrideWithValue(repo),
      ]);
      final ok = await vm(c).save({'store_name': 'x'});

      expect(ok, isFalse);
      expect(c.read(settingsAdminViewModelProvider).error, isNotNull);
    });
  });
}
