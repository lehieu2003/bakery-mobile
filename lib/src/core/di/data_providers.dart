import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/auth/session_manager.dart';
import 'package:bakery_mobile/src/core/config/app_config.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/storage/onboarding_storage.dart';
import 'package:bakery_mobile/src/core/storage/token_storage.dart';
import 'package:bakery_mobile/src/features/admin/categories/data/datasources/category_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/categories/data/repositories/category_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/customers/data/datasources/customer_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/customers/data/repositories/customer_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/data/datasources/dashboard_api_service.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/data/repositories/dashboard_repository.dart';
import 'package:bakery_mobile/src/features/admin/orders/data/datasources/order_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/orders/data/repositories/order_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/audit/data/datasources/audit_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/audit/data/repositories/audit_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/coupons/data/datasources/coupon_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/coupons/data/repositories/coupon_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/membership/data/datasources/membership_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/membership/data/repositories/membership_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/settings/data/datasources/settings_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/settings/data/repositories/settings_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/product-attributes/data/datasources/product_attribute_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/product-attributes/data/repositories/product_attribute_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/content/blog/data/datasources/blog_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/blog/data/repositories/blog_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/content/menu/data/datasources/menu_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/menu/data/repositories/menu_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/content/banners/data/datasources/banner_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/banners/data/repositories/banner_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/content/notifications/data/datasources/notification_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/notifications/data/repositories/notification_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/content/pages/data/datasources/page_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/pages/data/repositories/page_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/products/data/datasources/product_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/products/data/datasources/upload_api_service.dart';
import 'package:bakery_mobile/src/features/admin/products/data/repositories/product_admin_repository.dart';
import 'package:bakery_mobile/src/features/auth/data/datasources/auth_api_service.dart';
import 'package:bakery_mobile/src/features/auth/data/repositories/auth_repository.dart';
import 'package:bakery_mobile/src/features/addresses/data/datasources/address_api_service.dart';
import 'package:bakery_mobile/src/features/addresses/data/repositories/address_repository.dart';
import 'package:bakery_mobile/src/features/blog/data/datasources/blog_api_service.dart';
import 'package:bakery_mobile/src/features/blog/data/repositories/blog_repository.dart';
import 'package:bakery_mobile/src/features/catalog/data/datasources/catalog_api_service.dart';
import 'package:bakery_mobile/src/features/catalog/data/repositories/catalog_repository.dart';
import 'package:bakery_mobile/src/features/membership/data/datasources/membership_api_service.dart';
import 'package:bakery_mobile/src/features/membership/data/repositories/membership_repository.dart';
import 'package:bakery_mobile/src/features/notifications/data/datasources/notification_api_service.dart';
import 'package:bakery_mobile/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:bakery_mobile/src/features/orders/application/services/order_checkout_service.dart';
import 'package:bakery_mobile/src/features/orders/data/datasources/order_api_service.dart';
import 'package:bakery_mobile/src/features/orders/data/repositories/order_repository.dart';
import 'package:bakery_mobile/src/features/pages/data/datasources/page_api_service.dart';
import 'package:bakery_mobile/src/features/reviews/data/datasources/reviews_api_service.dart';
import 'package:bakery_mobile/src/features/reviews/data/repositories/reviews_repository.dart';
import 'package:bakery_mobile/src/features/pages/data/repositories/page_repository.dart';
import 'package:bakery_mobile/src/features/wishlist/data/datasources/wishlist_api_service.dart';
import 'package:bakery_mobile/src/features/wishlist/data/repositories/wishlist_repository.dart';

final appConfigProvider = Provider<AppConfig>((ref) => const AppConfig());
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
final onboardingStorageProvider = Provider<OnboardingStorage>(
  (ref) => OnboardingStorage(),
);

/// Rotates the bearer session before it expires. Its refresh call uses a
/// dedicated client bound to the token being rotated — going through
/// [apiClientProvider] would recurse into [SessionManager.validToken].
final sessionManagerProvider = Provider<SessionManager>((ref) {
  final config = ref.watch(appConfigProvider);
  return SessionManager(
    storage: ref.watch(tokenStorageProvider),
    refresh: (token) => AuthApiService(
      ApiClient(baseUrl: config.baseUrl, tokenProvider: () async => token),
    ).refreshSession(),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return ApiClient(
    baseUrl: config.baseUrl,
    tokenProvider: ref.watch(sessionManagerProvider).validToken,
  );
});

final addressApiServiceProvider = Provider<AddressApiService>(
  (ref) => AddressApiService(ref.watch(apiClientProvider)),
);
final authApiServiceProvider = Provider<AuthApiService>(
  (ref) => AuthApiService(ref.watch(apiClientProvider)),
);
final blogApiServiceProvider = Provider<BlogApiService>(
  (ref) => BlogApiService(ref.watch(apiClientProvider)),
);
final catalogApiServiceProvider = Provider<CatalogApiService>(
  (ref) => CatalogApiService(ref.watch(apiClientProvider)),
);
final membershipApiServiceProvider = Provider<MembershipApiService>(
  (ref) => MembershipApiService(ref.watch(apiClientProvider)),
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
final reviewsApiServiceProvider = Provider<ReviewsApiService>(
  (ref) => ReviewsApiService(ref.watch(apiClientProvider)),
);
final wishlistApiServiceProvider = Provider<WishlistApiService>(
  (ref) => WishlistApiService(ref.watch(apiClientProvider)),
);
final dashboardApiServiceProvider = Provider<DashboardApiService>(
  (ref) => DashboardApiService(ref.watch(apiClientProvider)),
);
final ordersAdminApiServiceProvider = Provider<OrderAdminApiService>(
  (ref) => OrderAdminApiService(ref.watch(apiClientProvider)),
);
final customersAdminApiServiceProvider = Provider<CustomerAdminApiService>(
  (ref) => CustomerAdminApiService(ref.watch(apiClientProvider)),
);
final productsAdminApiServiceProvider = Provider<ProductAdminApiService>(
  (ref) => ProductAdminApiService(ref.watch(apiClientProvider)),
);
final categoriesAdminApiServiceProvider = Provider<CategoryAdminApiService>(
  (ref) => CategoryAdminApiService(ref.watch(apiClientProvider)),
);

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepository(ref.watch(addressApiServiceProvider)),
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
final membershipRepositoryProvider = Provider<MembershipRepository>(
  (ref) => MembershipRepository(ref.watch(membershipApiServiceProvider)),
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
final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => ReviewsRepository(ref.watch(reviewsApiServiceProvider)),
);
final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => WishlistRepository(ref.watch(wishlistApiServiceProvider)),
);
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dashboardApiServiceProvider)),
);
final ordersAdminRepositoryProvider = Provider<OrderAdminRepository>(
  (ref) => OrderAdminRepository(ref.watch(ordersAdminApiServiceProvider)),
);
final customersAdminRepositoryProvider = Provider<CustomerAdminRepository>(
  (ref) => CustomerAdminRepository(ref.watch(customersAdminApiServiceProvider)),
);
final productsAdminRepositoryProvider = Provider<ProductAdminRepository>(
  (ref) => ProductAdminRepository(ref.watch(productsAdminApiServiceProvider)),
);
final categoriesAdminRepositoryProvider = Provider<CategoryAdminRepository>(
  (ref) =>
      CategoryAdminRepository(ref.watch(categoriesAdminApiServiceProvider)),
);

final orderCheckoutServiceProvider = Provider<OrderCheckoutService>(
  (ref) => OrderCheckoutService(ref.watch(orderRepositoryProvider)),
);

/// Product-form image uploads (`/api/upload`, chunked ≤5/request).
// Phase 5b: blog + menu.
final blogAdminApiServiceProvider = Provider<BlogAdminApiService>(
  (ref) => BlogAdminApiService(ref.watch(apiClientProvider)),
);
final blogAdminRepositoryProvider = Provider<BlogAdminRepository>(
  (ref) => BlogAdminRepository(ref.watch(blogAdminApiServiceProvider)),
);
final menuAdminApiServiceProvider = Provider<MenuAdminApiService>(
  (ref) => MenuAdminApiService(ref.watch(apiClientProvider)),
);
final menuAdminRepositoryProvider = Provider<MenuAdminRepository>(
  (ref) => MenuAdminRepository(ref.watch(menuAdminApiServiceProvider)),
);

// Phase 6: last-five admin modules.
final couponAdminApiServiceProvider = Provider<CouponAdminApiService>(
  (ref) => CouponAdminApiService(ref.watch(apiClientProvider)),
);
final couponAdminRepositoryProvider = Provider<CouponAdminRepository>(
  (ref) => CouponAdminRepository(ref.watch(couponAdminApiServiceProvider)),
);
final productAttributeAdminApiServiceProvider =
    Provider<ProductAttributeAdminApiService>(
      (ref) => ProductAttributeAdminApiService(ref.watch(apiClientProvider)),
    );
final productAttributeAdminRepositoryProvider =
    Provider<ProductAttributeAdminRepository>(
      (ref) => ProductAttributeAdminRepository(
        ref.watch(productAttributeAdminApiServiceProvider),
      ),
    );
final membershipAdminApiServiceProvider = Provider<MembershipAdminApiService>(
  (ref) => MembershipAdminApiService(ref.watch(apiClientProvider)),
);
final membershipAdminRepositoryProvider = Provider<MembershipAdminRepository>(
  (ref) =>
      MembershipAdminRepository(ref.watch(membershipAdminApiServiceProvider)),
);
final auditAdminApiServiceProvider = Provider<AuditAdminApiService>(
  (ref) => AuditAdminApiService(ref.watch(apiClientProvider)),
);
final auditAdminRepositoryProvider = Provider<AuditAdminRepository>(
  (ref) => AuditAdminRepository(ref.watch(auditAdminApiServiceProvider)),
);
final settingsAdminApiServiceProvider = Provider<SettingsAdminApiService>(
  (ref) => SettingsAdminApiService(ref.watch(apiClientProvider)),
);
final settingsAdminRepositoryProvider = Provider<SettingsAdminRepository>(
  (ref) => SettingsAdminRepository(ref.watch(settingsAdminApiServiceProvider)),
);

final uploadApiServiceProvider = Provider<UploadApiService>(
  (ref) => UploadApiService(ref.watch(apiClientProvider)),
);

// Phase 5a content modules.
final bannerAdminApiServiceProvider = Provider<BannerAdminApiService>(
  (ref) => BannerAdminApiService(ref.watch(apiClientProvider)),
);
final bannerAdminRepositoryProvider = Provider<BannerAdminRepository>(
  (ref) => BannerAdminRepository(ref.watch(bannerAdminApiServiceProvider)),
);
final notificationAdminApiServiceProvider =
    Provider<NotificationAdminApiService>(
      (ref) => NotificationAdminApiService(ref.watch(apiClientProvider)),
    );
final notificationAdminRepositoryProvider =
    Provider<NotificationAdminRepository>(
      (ref) => NotificationAdminRepository(
        ref.watch(notificationAdminApiServiceProvider),
      ),
    );
final pageAdminApiServiceProvider = Provider<PageAdminApiService>(
  (ref) => PageAdminApiService(ref.watch(apiClientProvider)),
);
final pageAdminRepositoryProvider = Provider<PageAdminRepository>(
  (ref) => PageAdminRepository(ref.watch(pageAdminApiServiceProvider)),
);
