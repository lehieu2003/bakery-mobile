import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/content/banners/data/datasources/banner_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/banners/data/repositories/banner_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/content/banners/domain/models/admin_banner.dart';
import 'package:bakery_mobile/src/features/admin/content/banners/presentation/controllers/banners_admin_view_model.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AdminBanner _banner(String id, int order, {bool active = true}) => AdminBanner(
  id: id,
  title: 'Banner $id',
  description: null,
  imageUrl: null,
  linkUrl: null,
  displayOrder: order,
  isActive: active,
  createdAt: DateTime.utc(2026, 1, 1),
);

class _FakeRepo extends BannerAdminRepository {
  _FakeRepo()
    : super(
        BannerAdminApiService(
          ApiClient(
            baseUrl: 'http://localhost:1',
            tokenProvider: () async => null,
          ),
        ),
      );

  Object? error;
  final reorderCalls = <List<String>>[];
  final bodies = <String, Map<String, dynamic>>{};

  @override
  Future<List<AdminBanner>> getBanners() async {
    final thrown = error;
    if (thrown != null) throw thrown;
    return [_banner('b-1', 0), _banner('b-2', 1), _banner('b-3', 2)];
  }

  @override
  Future<void> createBanner(Map<String, dynamic> body) async {
    bodies['create'] = body;
  }

  @override
  Future<void> updateBanner(String id, Map<String, dynamic> body) async {
    bodies[id] = body;
  }

  @override
  Future<void> deleteBanner(String id) async {
    bodies['delete:$id'] = {};
  }

  @override
  Future<void> reorderBanners(List<String> orderedIds) async {
    reorderCalls.add(orderedIds);
  }
}

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

void main() {
  late _FakeRepo repo;
  late _FakeAuthViewModel auth;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepo();
    auth = _FakeAuthViewModel();
    container = ProviderContainer(
      overrides: [
        bannerAdminRepositoryProvider.overrideWithValue(repo),
        authViewModelProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);
  });

  BannersAdminViewModel vm() =>
      container.read(bannersAdminViewModelProvider.notifier);
  BannersAdminState state() => container.read(bannersAdminViewModelProvider);

  test('load() fetches the ordered banner list', () async {
    await vm().load();

    expect(state().banners, hasLength(3));
    expect(state().banners.first.id, 'b-1');
    expect(state().isLoading, isFalse);
    expect(state().error, isNull);
  });

  test('save() creates with only provided keys then reloads', () async {
    await vm().load();

    final ok = await vm().save(
      title: 'Banner mới',
      imageUrl: 'https://cdn/x.jpg',
      isActive: true,
    );

    expect(ok, isTrue);
    expect(repo.bodies['create'], {
      'title': 'Banner mới',
      'imageUrl': 'https://cdn/x.jpg',
      'isActive': true,
    });
    // Reloaded after save.
    expect(state().banners, isNotEmpty);
  });

  test('save() edits an existing banner (partial body)', () async {
    await vm().load();

    final ok = await vm().save(id: 'b-1', title: 'Đã đổi');

    expect(ok, isTrue);
    expect(repo.bodies['b-1'], {'title': 'Đã đổi'});
  });

  test('move() sends the new sibling order then reloads', () async {
    await vm().load();

    await vm().move(2, up: true); // b-3 ↑ swaps with b-2

    expect(repo.reorderCalls.single, ['b-1', 'b-3', 'b-2']);
  });

  test('delete() removes then reloads', () async {
    await vm().load();

    await vm().remove('b-2');

    expect(repo.bodies.containsKey('delete:b-2'), isTrue);
  });

  test('401 logs out instead of erroring', () async {
    repo.error = ApiException('Unauthorized', statusCode: 401);
    await vm().load();

    expect(auth.logoutCalls, 1);
    expect(state().error, isNull);
  });

  test('generic error surfaces for retry', () async {
    repo.error = ApiException('Lỗi máy chủ', statusCode: 500);
    await vm().load();

    expect(state().error, 'Lỗi máy chủ');
  });
}
