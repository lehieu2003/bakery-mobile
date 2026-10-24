import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/content/blog/data/datasources/blog_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/blog/data/dtos/blog_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/content/blog/data/repositories/blog_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/content/blog/domain/models/blog_models.dart';
import 'package:bakery_mobile/src/features/admin/content/blog/presentation/controllers/blog_posts_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/content/menu/data/datasources/menu_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/menu/data/repositories/menu_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/content/menu/domain/models/menu_models.dart';
import 'package:bakery_mobile/src/features/admin/content/menu/presentation/controllers/menu_admin_view_model.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BlogPost _post(String id, {String status = 'PUBLISHED'}) => BlogPost(
  id: id,
  title: 'Bài $id',
  slug: 'bai-$id',
  status: status,
  createdAt: DateTime.utc(2026, 1, 1),
);

class _FakeBlogRepo extends BlogAdminRepository {
  _FakeBlogRepo()
    : super(
        BlogAdminApiService(
          ApiClient(
            baseUrl: 'http://localhost:1',
            tokenProvider: () async => null,
          ),
        ),
      );

  Object? error;
  final calls = <String, dynamic>{};
  List<BlogPost> posts = [_post('p-1'), _post('p-2', status: 'DRAFT')];

  @override
  Future<BlogPostPage> getPosts({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final thrown = error;
    if (thrown != null) throw thrown;
    calls['list'] = {'page': page, 'search': search};
    return BlogPostPage(items: posts, total: posts.length, totalPages: 1);
  }

  @override
  Future<void> createPost(Map<String, dynamic> body) async {
    final thrown = error;
    if (thrown != null) throw thrown;
    calls['create'] = body;
  }

  @override
  Future<void> updatePostStatus(String id, String status) async {
    calls['status:$id'] = status;
  }

  @override
  Future<void> deletePost(String id) async {
    calls['delete:$id'] = true;
  }
}

class _FakeMenuRepo extends MenuAdminRepository {
  _FakeMenuRepo()
    : super(
        MenuAdminApiService(
          ApiClient(
            baseUrl: 'http://localhost:1',
            tokenProvider: () async => null,
          ),
        ),
      );

  Object? error;
  List<AdminMenuItem> items = [];
  final bodies = <String, Map<String, dynamic>>{};

  @override
  Future<List<AdminMenuItem>> getMenu() async {
    final thrown = error;
    if (thrown != null) throw thrown;
    return items;
  }

  @override
  Future<void> createMenuItem(Map<String, dynamic> body) async {
    bodies['create'] = body;
    items = [
      ...items,
      AdminMenuItem(
        id: 'm-${items.length + 1}',
        title: body['title'].toString(),
        url: body['url']?.toString(),
        displayOrder: items.length,
        isActive: true,
      ),
    ];
  }

  @override
  Future<void> deleteMenuItem(String id) async {
    bodies['delete:$id'] = {};
    items = items.where((item) => item.id != id).toList();
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
  late _FakeBlogRepo blogRepo;
  late _FakeMenuRepo menuRepo;
  late _FakeAuthViewModel auth;
  late ProviderContainer container;

  setUp(() {
    blogRepo = _FakeBlogRepo();
    menuRepo = _FakeMenuRepo();
    auth = _FakeAuthViewModel();
    container = ProviderContainer(
      overrides: [
        blogAdminRepositoryProvider.overrideWithValue(blogRepo),
        menuAdminRepositoryProvider.overrideWithValue(menuRepo),
        authViewModelProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);
  });

  BlogPostsAdminViewModel postsVm() =>
      container.read(blogPostsAdminViewModelProvider.notifier);
  BlogPostsAdminState postsState() =>
      container.read(blogPostsAdminViewModelProvider);
  MenuAdminViewModel menuVm() =>
      container.read(menuAdminViewModelProvider.notifier);
  MenuAdminState menuState() => container.read(menuAdminViewModelProvider);

  group('blog posts', () {
    test('load() fetches the list', () async {
      await postsVm().load();

      expect(postsState().items, hasLength(2));
      expect(postsState().items.last.status, 'DRAFT');
    });

    test('create() gates an empty title without calling the repo', () async {
      await postsVm().load();

      final ok = await postsVm().create(title: '', content: 'x');

      expect(ok, isFalse);
      expect(blogRepo.calls.containsKey('create'), isFalse);
      expect(postsState().error, contains('Tiêu đề'));
    });

    test('create() sends title/slug/status and reloads', () async {
      await postsVm().load();

      final ok = await postsVm().create(
        title: 'Bài mới',
        content: 'Nội dung bài',
        status: 'DRAFT',
      );

      expect(ok, isTrue);
      final body = blogRepo.calls['create']! as Map<String, dynamic>;
      expect(body['title'], 'Bài mới');
      expect(body['status'], 'DRAFT');
    });

    test('publish toggle hits the dedicated /status endpoint', () async {
      await postsVm().load();

      await postsVm().setStatus('p-2', 'PUBLISHED');

      expect(blogRepo.calls['status:p-2'], 'PUBLISHED');
    });

    test('401 logs out', () async {
      blogRepo.error = ApiException('Unauthorized', statusCode: 401);
      await postsVm().load();

      expect(auth.logoutCalls, 1);
    });
  });

  group('menu', () {
    test(
      'load() on an empty menu keeps the CTA-friendly empty state',
      () async {
        await menuVm().load();

        expect(menuState().items, isEmpty);
        expect(menuState().error, isNull);
      },
    );

    test('save() create sends title/url/type and reloads', () async {
      await menuVm().load();

      final ok = await menuVm().save(title: 'Khuyến mãi', url: '/khuyen-mai');

      expect(ok, isTrue);
      expect(menuRepo.bodies['create'], {
        'title': 'Khuyến mãi',
        'type': 'LINK',
        'url': '/khuyen-mai',
        'isActive': true,
      });
      expect(menuState().items.single.title, 'Khuyến mãi');
    });

    test('delete() removes then reloads', () async {
      await menuVm().load();
      await menuVm().save(title: 'Tạm', url: '/tam');
      await menuVm().remove(menuState().items.first.id);

      expect(menuRepo.bodies.containsKey('delete:m-1'), isTrue);
      expect(menuState().items, isEmpty);
    });

    test('401 logs out', () async {
      menuRepo.error = ApiException('Unauthorized', statusCode: 401);
      await menuVm().load();

      expect(auth.logoutCalls, 1);
    });
  });
}
