import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bakery_mobile/src/core/config/app_config.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/storage/token_storage.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/auth/data/repositories/auth_repository.dart';
import 'package:bakery_mobile/src/features/blog/data/repositories/blog_repository.dart';
import 'package:bakery_mobile/src/features/catalog/data/repositories/catalog_repository.dart';
import 'package:bakery_mobile/src/features/chatbot/data/repositories/chat_repository.dart';
import 'package:bakery_mobile/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:bakery_mobile/src/features/orders/data/repositories/order_repository.dart';
import 'package:bakery_mobile/src/features/pages/data/repositories/page_repository.dart';
import 'package:bakery_mobile/src/features/auth/data/datasources/auth_api_service.dart';
import 'package:bakery_mobile/src/features/blog/data/datasources/blog_api_service.dart';
import 'package:bakery_mobile/src/features/catalog/data/datasources/catalog_api_service.dart';
import 'package:bakery_mobile/src/features/chatbot/data/datasources/chat_api_service.dart';
import 'package:bakery_mobile/src/features/notifications/data/datasources/notification_api_service.dart';
import 'package:bakery_mobile/src/features/orders/data/datasources/order_api_service.dart';
import 'package:bakery_mobile/src/features/pages/data/datasources/page_api_service.dart';
import 'package:bakery_mobile/src/features/navigation/presentation/screens/app_shell.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:bakery_mobile/src/features/cart/presentation/controllers/cart_view_model.dart';
import 'package:bakery_mobile/src/features/chatbot/presentation/controllers/chatbot_view_model.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/controllers/notifications_view_model.dart';
import 'package:bakery_mobile/src/features/orders/presentation/controllers/orders_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const config = AppConfig();
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(
    baseUrl: config.baseUrl,
    tokenProvider: tokenStorage.readToken,
  );

  final authRepository = AuthRepository(
    tokenStorage: tokenStorage,
    authApiService: AuthApiService(apiClient),
  );
  final catalogRepository = CatalogRepository(CatalogApiService(apiClient));
  final blogRepository = BlogRepository(BlogApiService(apiClient));
  final chatRepository = ChatRepository(ChatApiService(apiClient));
  final notificationRepository = NotificationRepository(
    NotificationApiService(apiClient),
  );
  final pageRepository = PageRepository(PageApiService(apiClient));
  final orderRepository = OrderRepository(OrderApiService(apiClient));

  runApp(
    BakeryMobileApp(
      authRepository: authRepository,
      catalogRepository: catalogRepository,
      blogRepository: blogRepository,
      chatRepository: chatRepository,
      notificationRepository: notificationRepository,
      pageRepository: pageRepository,
      orderRepository: orderRepository,
    ),
  );
}

class BakeryMobileApp extends StatelessWidget {
  const BakeryMobileApp({
    super.key,
    required this.authRepository,
    required this.catalogRepository,
    required this.blogRepository,
    required this.chatRepository,
    required this.notificationRepository,
    required this.pageRepository,
    required this.orderRepository,
  });

  final AuthRepository authRepository;
  final CatalogRepository catalogRepository;
  final BlogRepository blogRepository;
  final ChatRepository chatRepository;
  final NotificationRepository notificationRepository;
  final PageRepository pageRepository;
  final OrderRepository orderRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: authRepository),
        Provider.value(value: catalogRepository),
        Provider.value(value: blogRepository),
        Provider.value(value: chatRepository),
        Provider.value(value: notificationRepository),
        Provider.value(value: pageRepository),
        Provider.value(value: orderRepository),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authRepository)..bootstrap(),
        ),
        ChangeNotifierProvider(create: (_) => CartViewModel()),
        ChangeNotifierProvider(create: (_) => ChatbotViewModel(chatRepository)),
        ChangeNotifierProvider(
          create: (_) => NotificationsViewModel(notificationRepository),
        ),
        ChangeNotifierProvider(create: (_) => OrdersViewModel(orderRepository)),
      ],
      child: MaterialApp(
        title: 'Bakery Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppShell(),
      ),
    );
  }
}


