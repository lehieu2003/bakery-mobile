import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/content/notifications/data/datasources/notification_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/notifications/data/dtos/notification_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/content/notifications/data/repositories/notification_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/content/notifications/presentation/controllers/notifications_admin_view_model.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo extends NotificationAdminRepository {
  _FakeRepo()
    : super(
        NotificationAdminApiService(
          ApiClient(
            baseUrl: 'http://localhost:1',
            tokenProvider: () async => null,
          ),
        ),
      );

  Object? error;
  final calls = <String, dynamic>{};
  Map<String, dynamic>? Function(String? status)? listOverride;

  @override
  Future<NotificationAdminPage> getNotifications({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final thrown = error;
    if (thrown != null) throw thrown;
    calls['list'] = {'page': page, 'search': search, 'status': status};
    final override = listOverride?.call(status);
    return NotificationAdminListDto.fromJson(
      override ??
          {
            'notifications': [
              {
                'id': 'n-1',
                'title': 'Khuyến mãi',
                'content': 'Giảm 20%',
                'status': 'PUBLISHED',
                'createdAt': '2026-01-01T00:00:00.000Z',
              },
            ],
            'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
          },
    );
  }

  @override
  Future<void> createNotification(Map<String, dynamic> body) async {
    calls['create'] = body;
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
        notificationAdminRepositoryProvider.overrideWithValue(repo),
        authViewModelProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);
  });

  NotificationsAdminViewModel vm() =>
      container.read(notificationsAdminViewModelProvider.notifier);
  NotificationsAdminState state() =>
      container.read(notificationsAdminViewModelProvider);

  test('load() fetches page 1 with no filters', () async {
    await vm().load();

    expect(state().items.single.title, 'Khuyến mãi');
    expect(repo.calls['list'], {'page': 1, 'search': null, 'status': null});
  });

  test('setStatusFilter passes the wire status and resets to page 1', () async {
    await vm().load();
    await vm().setStatusFilter('PUBLISHED');

    expect(repo.calls['list'], {
      'page': 1,
      'search': null,
      'status': 'PUBLISHED',
    });
  });

  test('create() gates a missing title without calling the repo', () async {
    await vm().load();

    final ok = await vm().create(title: '', content: 'Nội dung');

    expect(ok, isFalse);
    expect(repo.calls.containsKey('create'), isFalse);
    expect(state().error, contains('Tiêu đề'));
  });

  test('create() sends the body then reloads', () async {
    await vm().load();

    final ok = await vm().create(
      title: 'Thông báo mới',
      content: 'Nội dung thông báo',
      status: 'DRAFT',
    );

    expect(ok, isTrue);
    expect(repo.calls['create'], {
      'title': 'Thông báo mới',
      'content': 'Nội dung thông báo',
      'status': 'DRAFT',
    });
    expect(state().items, isNotEmpty);
  });

  test('401 logs out', () async {
    repo.error = ApiException('Unauthorized', statusCode: 401);
    await vm().load();

    expect(auth.logoutCalls, 1);
  });
}
