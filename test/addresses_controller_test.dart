import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/addresses/data/datasources/address_api_service.dart';
import 'package:bakery_mobile/src/features/addresses/data/repositories/address_repository.dart';
import 'package:bakery_mobile/src/features/addresses/presentation/controllers/addresses_view_model.dart';
import 'package:bakery_mobile/src/features/orders/data/datasources/order_api_service.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:bakery_mobile/src/features/orders/data/repositories/order_repository.dart';
import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:bakery_mobile/src/features/cart/domain/models/cart_item.dart';
import 'package:bakery_mobile/src/features/cart/presentation/controllers/cart_view_model.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/checkout_screen.dart';

/// In-memory fake mirroring the server semantics of `/api/addresses`:
/// - first created address is forced default;
/// - setting `isDefault: true` unsets every other default;
/// - updating/deleting an address the user does not own fails (404).
class _FakeAddressApiService extends AddressApiService {
  _FakeAddressApiService([List<Map<String, dynamic>>? seed])
    : super(
        ApiClient(
          baseUrl: 'http://localhost:1',
          tokenProvider: () async => null,
        ),
      ) {
    _nextId = _records.length + 1;
    if (seed != null) {
      _records.addAll(seed);
      _nextId = _records.length + 1;
    }
  }

  final List<Map<String, dynamic>> _records = [];
  int _nextId = 1;

  void _applyDefaultRule(String id, bool isDefault) {
    if (!isDefault) return;
    for (final record in _records) {
      if (record['id'] != id) record['isDefault'] = false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAddresses() async {
    final sorted = [..._records];
    sorted.sort((a, b) {
      final aDefault = a['isDefault'] == true;
      final bDefault = b['isDefault'] == true;
      if (aDefault != bDefault) return aDefault ? -1 : 1;
      return 0;
    });
    return sorted.map((record) => Map<String, dynamic>.from(record)).toList();
  }

  @override
  Future<Map<String, dynamic>> createAddress({
    required String fullName,
    required String phone,
    required String street,
    required String ward,
    required String district,
    required String province,
    bool isDefault = false,
  }) async {
    // Server rule: a user's first address is always their default one.
    final isFirstAddress = _records.isEmpty;
    final effectiveDefault = isDefault || isFirstAddress;
    final record = <String, dynamic>{
      'id': 'addr-${_nextId++}',
      'userId': 'user-1',
      'fullName': fullName,
      'phone': phone,
      'street': street,
      'ward': ward,
      'district': district,
      'province': province,
      'isDefault': effectiveDefault,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _records.add(record);
    _applyDefaultRule(record['id'] as String, effectiveDefault);
    return Map<String, dynamic>.from(record);
  }

  @override
  Future<Map<String, dynamic>> updateAddress(
    String id, {
    String? fullName,
    String? phone,
    String? street,
    String? ward,
    String? district,
    String? province,
    bool? isDefault,
  }) async {
    final index = _records.indexWhere((record) => record['id'] == id);
    if (index < 0) {
      throw Exception('Address not found');
    }
    final record = _records[index];
    final updated = Map<String, dynamic>.from(record);
    if (fullName != null) updated['fullName'] = fullName.trim();
    if (phone != null) updated['phone'] = phone.trim();
    if (street != null) updated['street'] = street.trim();
    if (ward != null) updated['ward'] = ward.trim();
    if (district != null) updated['district'] = district.trim();
    if (province != null) updated['province'] = province.trim();
    if (isDefault != null) updated['isDefault'] = isDefault;
    _records[index] = updated;
    _applyDefaultRule(id, updated['isDefault'] == true);
    return Map<String, dynamic>.from(updated);
  }

  @override
  Future<void> deleteAddress(String id) async {
    final index = _records.indexWhere((record) => record['id'] == id);
    if (index < 0) {
      throw Exception('Address not found');
    }
    _records.removeAt(index);
  }
}

AddressesViewModel _newViewModel(ProviderContainer container) {
  return container.read(addressesViewModelProvider.notifier);
}

void main() {
  group('AddressesViewModel (fake datasource)', () {
    late ProviderContainer container;
    late _FakeAddressApiService datasource;

    setUp(() {
      datasource = _FakeAddressApiService();
      container = ProviderContainer(
        overrides: [
          addressRepositoryProvider.overrideWith(
            (ref) => AddressRepository(datasource),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('load() populates items and toggles isLoading', () async {
      final vm = _newViewModel(container);
      expect(container.read(addressesViewModelProvider).items, isEmpty);
      expect(container.read(addressesViewModelProvider).isLoading, isFalse);

      final loading = vm.load();
      expect(container.read(addressesViewModelProvider).isLoading, isTrue);
      await loading;

      final state = container.read(addressesViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.items, isEmpty, reason: 'fake datasource starts empty');
    });

    test('load() failure surfaces an error message', () async {
      final failingDatasource = _FailingAddressApiService();
      final failingContainer = ProviderContainer(
        overrides: [
          addressRepositoryProvider.overrideWith(
            (ref) => AddressRepository(failingDatasource),
          ),
        ],
      );
      addTearDown(failingContainer.dispose);

      await failingContainer.read(addressesViewModelProvider.notifier).load();

      final state = failingContainer.read(addressesViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
      expect(state.items, isEmpty);
    });

    test('add() appends to the list; first address becomes default', () async {
      final vm = _newViewModel(container);

      final first = await vm.add(
        fullName: 'Nguyễn Văn A',
        phone: '0901234567',
        street: '12 Nguyễn Trãi',
        ward: 'Phường Bến Nghé',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
      );
      expect(first, isNotNull);
      expect(container.read(addressesViewModelProvider).items, hasLength(1));
      expect(
        container.read(addressesViewModelProvider).items.first.isDefault,
        isTrue,
        reason: 'server forces the first address to be the default',
      );

      final second = await vm.add(
        fullName: 'Trần Thị B',
        phone: '0987654321',
        street: '9 Lê Lợi',
        ward: 'Phường Bến Thành',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
      );
      final items = container.read(addressesViewModelProvider).items;
      expect(items, hasLength(2));
      expect(items.last.id, second!.id);
      expect(items.last.isDefault, isFalse);
    });

    test('delete() removes the address from the list', () async {
      final vm = _newViewModel(container);
      final first = await vm.add(
        fullName: 'Nguyễn Văn A',
        phone: '0901234567',
        street: '12 Nguyễn Trãi',
        ward: 'Phường Bến Nghé',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
      );
      final second = await vm.add(
        fullName: 'Trần Thị B',
        phone: '0987654321',
        street: '9 Lê Lợi',
        ward: 'Phường Bến Thành',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
      );
      expect(container.read(addressesViewModelProvider).items, hasLength(2));

      await vm.delete(first!.id);

      final items = container.read(addressesViewModelProvider).items;
      expect(items, hasLength(1));
      expect(items.first.id, second!.id);
    });

    test('delete() failure keeps the list and sets an error', () async {
      final vm = _newViewModel(container);
      final first = await vm.add(
        fullName: 'Nguyễn Văn A',
        phone: '0901234567',
        street: '12 Nguyễn Trãi',
        ward: 'Phường Bến Nghé',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
      );

      await vm.delete('does-not-exist');

      final state = container.read(addressesViewModelProvider);
      expect(state.error, isNotNull);
      expect(state.items, hasLength(1));
      expect(state.items.first.id, first!.id);
    });

    test('setDefault() leaves exactly one default address', () async {
      final vm = _newViewModel(container);
      final first = await vm.add(
        fullName: 'Nguyễn Văn A',
        phone: '0901234567',
        street: '12 Nguyễn Trãi',
        ward: 'Phường Bến Nghé',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
      );
      final second = await vm.add(
        fullName: 'Trần Thị B',
        phone: '0987654321',
        street: '9 Lê Lợi',
        ward: 'Phường Bến Thành',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
      );

      await vm.setDefault(second!.id);

      final items = container.read(addressesViewModelProvider).items;
      expect(items.where((item) => item.isDefault), hasLength(1));
      expect(items.firstWhere((item) => item.isDefault).id, second.id);
      expect(
        items.firstWhere((item) => item.id == first!.id).isDefault,
        isFalse,
      );
    });

    test('update() applies edited fields to the list', () async {
      final vm = _newViewModel(container);
      final first = await vm.add(
        fullName: 'Nguyễn Văn A',
        phone: '0901234567',
        street: '12 Nguyễn Trãi',
        ward: 'Phường Bến Nghé',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
      );

      await vm.update(first!.id, fullName: 'Nguyễn Văn B', phone: '0909999999');

      final updated = container
          .read(addressesViewModelProvider)
          .items
          .firstWhere((item) => item.id == first.id);
      expect(updated.fullName, 'Nguyễn Văn B');
      expect(updated.phone, '0909999999');
      expect(updated.street, '12 Nguyễn Trãi');
    });
  });

  group('checkout integration (widget)', () {
    late _CapturingOrderRepository orderRepository;
    late _FakeAddressApiService addressDatasource;

    Widget buildHost() {
      return ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(_FakeAuthViewModel.new),
          cartViewModelProvider.overrideWith(_FakeCartViewModel.new),
          orderRepositoryProvider.overrideWithValue(orderRepository),
          addressRepositoryProvider.overrideWith(
            (ref) => AddressRepository(addressDatasource),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CheckoutScreen(),
        ),
      );
    }

    setUp(() {
      orderRepository = _CapturingOrderRepository();
    });

    testWidgets('saved address pick sends addressId and joined address line', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      addressDatasource = _FakeAddressApiService();
      await addressDatasource.createAddress(
        fullName: 'Nguyễn Văn A',
        phone: '0901234567',
        street: '12 Nguyễn Trãi',
        ward: 'Phường Bến Nghé',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
      );
      await addressDatasource.createAddress(
        fullName: 'Trần Thị B',
        phone: '0987654321',
        street: '9 Lê Lợi',
        ward: 'Phường Bến Thành',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
      );

      await tester.pumpWidget(buildHost());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giao tận nơi'));
      await tester.pumpAndSettle();

      // Both saved addresses appear in the radio list; the default is
      // pre-selected ("Nguyễn Văn A" first). Match Text widgets only —
      // the auto-selected address also fills the name/phone fields, so
      // find.text would hit the EditableText too.
      Finder radioTitle(String name) => find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == name,
      );
      expect(find.text('Địa chỉ đã lưu'), findsOneWidget);
      expect(radioTitle('Nguyễn Văn A'), findsOneWidget);
      expect(radioTitle('Trần Thị B'), findsOneWidget);

      // Pick the second (non-default) saved address.
      await tester.tap(radioTitle('Trần Thị B'));
      await tester.pump();

      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Họ tên').first,
            )
            .controller!
            .text,
        'Trần Thị B',
      );

      await tester.scrollUntilVisible(
        find.text('Đặt hàng'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đặt hàng'));
      await tester.pumpAndSettle();

      expect(orderRepository.capturedDeliveryMethod, DeliveryMethod.delivery);
      expect(orderRepository.capturedAddressId, 'addr-2');
      expect(
        orderRepository.capturedAddress,
        '9 Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh',
      );
    });

    testWidgets('manual entry sends no addressId', (tester) async {
      SharedPreferences.setMockInitialValues({
        'checkout_draft_name': 'Lê Văn C',
        'checkout_draft_phone': '0905555555',
        'checkout_draft_address': 'Số 7 đường Thủ Khoa Huân',
      });
      addressDatasource = _FakeAddressApiService();
      await addressDatasource.createAddress(
        fullName: 'Nguyễn Văn A',
        phone: '0901234567',
        street: '12 Nguyễn Trãi',
        ward: 'Phường Bến Nghé',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
      );

      await tester.pumpWidget(buildHost());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giao tận nơi'));
      await tester.pumpAndSettle();

      // A draft address is restored, so no saved address gets auto-selected
      // and the manual-entry flow keeps working.
      await tester.scrollUntilVisible(
        find.text('Đặt hàng'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đặt hàng'));
      await tester.pumpAndSettle();

      expect(orderRepository.capturedAddressId, isNull);
      expect(orderRepository.capturedAddress, 'Số 7 đường Thủ Khoa Huân');
    });

    testWidgets('hand-editing the address clears the picked addressId', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      addressDatasource = _FakeAddressApiService();
      await addressDatasource.createAddress(
        fullName: 'Nguyễn Văn A',
        phone: '0901234567',
        street: '12 Nguyễn Trãi',
        ward: 'Phường Bến Nghé',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
      );

      await tester.pumpWidget(buildHost());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giao tận nơi'));
      await tester.pumpAndSettle();

      // The default saved address is auto-selected and fills the fields.
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Địa chỉ giao hàng'),
            )
            .controller!
            .text,
        '12 Nguyễn Trãi, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Địa chỉ giao hàng'),
        '12 Nguyễn Trãi, thêm ghi chú',
      );
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Đặt hàng'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đặt hàng'));
      await tester.pumpAndSettle();

      expect(orderRepository.capturedAddressId, isNull);
      expect(orderRepository.capturedAddress, '12 Nguyễn Trãi, thêm ghi chú');
    });

    testWidgets('guest checkout shows no saved addresses and sends no id', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      addressDatasource = _FakeAddressApiService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith(_GuestAuthViewModel.new),
            cartViewModelProvider.overrideWith(_FakeCartViewModel.new),
            orderRepositoryProvider.overrideWithValue(orderRepository),
            addressRepositoryProvider.overrideWith(
              (ref) => AddressRepository(addressDatasource),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Địa chỉ đã lưu'), findsNothing);

      await tester.tap(find.text('Giao tận nơi'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Họ tên'),
        'Khách vãng lai',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Số điện thoại'),
        '0901234567',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Địa chỉ giao hàng'),
        'Số 1 đường Ếch',
      );
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Đặt hàng'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đặt hàng'));
      await tester.pumpAndSettle();

      expect(orderRepository.capturedAddressId, isNull);
      expect(orderRepository.capturedAddress, 'Số 1 đường Ếch');
    });
  });
}

class _FailingAddressApiService extends AddressApiService {
  _FailingAddressApiService()
    : super(
        ApiClient(
          baseUrl: 'http://localhost:1',
          tokenProvider: () async => null,
        ),
      );

  @override
  Future<List<Map<String, dynamic>>> getAddresses() async {
    throw Exception('Network error');
  }
}

class _FakeAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(
    user: User(id: 'user-1', email: 'test@bakery.vn', role: 'CUSTOMER'),
  );
}

class _GuestAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState();
}

class _FakeCartViewModel extends CartViewModel {
  @override
  CartState build() => const CartState(
    items: [
      CartItem(productId: 'p-1', name: 'Baguette', price: 50000, quantity: 1),
    ],
  );
}

class _CapturingOrderRepository extends OrderRepository {
  _CapturingOrderRepository()
    : super(
        OrderApiService(
          ApiClient(
            baseUrl: 'http://localhost:1',
            tokenProvider: () async => null,
          ),
        ),
      );

  String? capturedAddressId;
  String? capturedAddress;
  DeliveryMethod? capturedDeliveryMethod;

  @override
  Future<CreateOrderResult> createOrder({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? customerAddress,
    String? addressId,
    required String paymentMethod,
    required DeliveryMethod deliveryMethod,
    List<String> incentiveCodes = const [],
    required List<Map<String, dynamic>> items,
    required String idempotencyKey,
  }) async {
    capturedDeliveryMethod = deliveryMethod;
    capturedAddressId = addressId;
    capturedAddress = customerAddress;
    return CreateOrderResult(
      order: Order(
        id: 'order-1',
        orderNumber: 'ORD-1',
        status: 'PENDING',
        total: 50000,
        createdAt: DateTime(2026, 1, 1),
        orderItems: const [],
      ),
    );
  }

  @override
  Future<PreviewIncentiveResult> previewIncentives({
    required DeliveryMethod deliveryMethod,
    required List<String> incentiveCodes,
    required List<Map<String, dynamic>> items,
  }) async {
    return const PreviewIncentiveResult(
      subtotal: 50000,
      membershipDiscount: 0,
      couponDiscount: 0,
      totalDiscount: 0,
      total: 50000,
    );
  }

  @override
  Future<List<AvailableIncentive>> getAvailableIncentives({
    required double subtotal,
    required List<Map<String, dynamic>> cart,
  }) async {
    return const [];
  }
}
