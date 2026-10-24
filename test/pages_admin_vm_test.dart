import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/content/pages/data/datasources/page_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/pages/data/repositories/page_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/content/pages/domain/models/admin_page.dart';
import 'package:bakery_mobile/src/features/admin/content/pages/presentation/controllers/pages_admin_view_model.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo extends PageAdminRepository {
  _FakeRepo()
    : super(
        PageAdminApiService(
          ApiClient(
            baseUrl: 'http://localhost:1',
            tokenProvider: () async => null,
          ),
        ),
      );

  Object? error;
  final bodies = <String, Map<String, dynamic>>{};

  @override
  Future<List<AdminPage>> getPages() async {
    final thrown = error;
    if (thrown != null) throw thrown;
    return [
      AdminPage(
        id: 'p-1',
        title: 'Về chúng tôi',
        slug: 've-chung-toi',
        content: 'Nội dung',
        isPublished: true,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    ];
  }

  @override
  Future<void> createPage(Map<String, dynamic> body) async {
    bodies['create'] = body;
  }

  @override
  Future<void> updatePage(String id, Map<String, dynamic> body) async {
    bodies[id] = body;
  }

  @override
  Future<void> deletePage(String id) async {
    bodies['delete:$id'] = {};
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
        pageAdminRepositoryProvider.overrideWithValue(repo),
        authViewModelProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);
  });

  PagesAdminViewModel vm() =>
      container.read(pagesAdminViewModelProvider.notifier);
  PagesAdminState state() => container.read(pagesAdminViewModelProvider);

  test('load() fetches the page list', () async {
    await vm().load();

    expect(state().pages.single.title, 'Về chúng tôi');
    expect(state().pages.single.isPublished, isTrue);
  });

  test('save() create omits empty slug (server auto-generates)', () async {
    await vm().load();

    final ok = await vm().save(
      title: 'Trang mới',
      content: 'Nội dung\nvới xuống dòng',
      isPublished: false,
    );

    expect(ok, isTrue);
    expect(repo.bodies['create'], {
      'title': 'Trang mới',
      'content': 'Nội dung\nvới xuống dòng',
      'isPublished': false,
    });
  });

  test('save() edit sends only changed keys', () async {
    await vm().load();

    final ok = await vm().save(id: 'p-1', title: 'Đã đổi tên');

    expect(ok, isTrue);
    expect(repo.bodies['p-1'], {'title': 'Đã đổi tên'});
  });

  test('delete() removes then reloads', () async {
    await vm().load();

    await vm().remove('p-1');

    expect(repo.bodies.containsKey('delete:p-1'), isTrue);
  });

  test('401 logs out', () async {
    repo.error = ApiException('Unauthorized', statusCode: 401);
    await vm().load();

    expect(auth.logoutCalls, 1);
  });
}
