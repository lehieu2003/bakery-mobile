import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/config/app_config.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/storage/token_storage.dart';
import 'package:bakery_mobile/src/features/auth/data/datasources/auth_api_service.dart';
import 'package:bakery_mobile/src/features/auth/data/repositories/auth_repository.dart';
import 'package:bakery_mobile/src/features/blog/data/datasources/blog_api_service.dart';
import 'package:bakery_mobile/src/features/blog/data/repositories/blog_repository.dart';
import 'package:bakery_mobile/src/features/catalog/data/datasources/catalog_api_service.dart';
import 'package:bakery_mobile/src/features/catalog/data/repositories/catalog_repository.dart';
import 'package:bakery_mobile/src/features/chatbot/data/datasources/chat_api_service.dart';
import 'package:bakery_mobile/src/features/chatbot/data/repositories/chat_repository.dart';
import 'package:bakery_mobile/src/features/notifications/data/datasources/notification_api_service.dart';
import 'package:bakery_mobile/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:bakery_mobile/src/features/orders/application/services/order_checkout_service.dart';
import 'package:bakery_mobile/src/features/orders/data/datasources/order_api_service.dart';
import 'package:bakery_mobile/src/features/orders/data/repositories/order_repository.dart';
import 'package:bakery_mobile/src/features/pages/data/datasources/page_api_service.dart';
import 'package:bakery_mobile/src/features/pages/data/repositories/page_repository.dart';

final appConfigProvider = Provider<AppConfig>((ref) => const AppConfig());
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(
    baseUrl: config.baseUrl,
    tokenProvider: tokenStorage.readToken,
  );
});

final authApiServiceProvider = Provider<AuthApiService>(
  (ref) => AuthApiService(ref.watch(apiClientProvider)),
);
final blogApiServiceProvider = Provider<BlogApiService>(
  (ref) => BlogApiService(ref.watch(apiClientProvider)),
);
final catalogApiServiceProvider = Provider<CatalogApiService>(
  (ref) => CatalogApiService(ref.watch(apiClientProvider)),
);
final chatApiServiceProvider = Provider<ChatApiService>(
  (ref) => ChatApiService(ref.watch(apiClientProvider)),
);
final notificationApiServiceProvider = Provider<NotificationApiService>(
  (ref) => NotificationApiService(ref.watch(apiClientProvider)),
);
final orderApiServiceProvider = Provider<OrderApiService>(
  (ref) => OrderApiService(ref.watch(apiClientProvider)),
);
final pageApiServiceProvider = Provider<PageApiService>(
  (ref) => PageApiService(ref.watch(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    tokenStorage: ref.watch(tokenStorageProvider),
    authApiService: ref.watch(authApiServiceProvider),
  );
});
final blogRepositoryProvider = Provider<BlogRepository>(
  (ref) => BlogRepository(ref.watch(blogApiServiceProvider)),
);
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(catalogApiServiceProvider)),
);
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(chatApiServiceProvider)),
);
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(notificationApiServiceProvider)),
);
final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(ref.watch(orderApiServiceProvider)),
);
final pageRepositoryProvider = Provider<PageRepository>(
  (ref) => PageRepository(ref.watch(pageApiServiceProvider)),
);

final orderCheckoutServiceProvider = Provider<OrderCheckoutService>(
  (ref) => OrderCheckoutService(ref.watch(orderRepositoryProvider)),
);
