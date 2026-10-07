import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:bakery_mobile/src/features/addresses/presentation/controllers/addresses_view_model.dart';
import 'package:bakery_mobile/src/features/blog/presentation/controllers/blog_view_model.dart';
import 'package:bakery_mobile/src/features/cart/presentation/controllers/cart_view_model.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/controllers/home_view_model.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/controllers/search_view_model.dart';
import 'package:bakery_mobile/src/features/chatbot/presentation/controllers/chatbot_view_model.dart';
import 'package:bakery_mobile/src/features/membership/presentation/controllers/membership_view_model.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/controllers/notifications_view_model.dart';
import 'package:bakery_mobile/src/features/onboarding/presentation/controllers/onboarding_view_model.dart';
import 'package:bakery_mobile/src/features/orders/presentation/controllers/orders_view_model.dart';
import 'package:bakery_mobile/src/features/pages/presentation/controllers/pages_view_model.dart';
import 'package:bakery_mobile/src/features/wishlist/presentation/controllers/wishlist_view_model.dart';

final addressesViewModelProvider =
    NotifierProvider<AddressesViewModel, AddressesState>(
      AddressesViewModel.new,
    );
final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);
final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(
      OnboardingViewModel.new,
    );
final cartViewModelProvider = NotifierProvider<CartViewModel, CartState>(
  CartViewModel.new,
);
final chatbotViewModelProvider =
    NotifierProvider<ChatbotViewModel, ChatbotState>(ChatbotViewModel.new);
final membershipViewModelProvider =
    NotifierProvider<MembershipViewModel, MembershipState>(
      MembershipViewModel.new,
    );
final notificationsViewModelProvider =
    NotifierProvider<NotificationsViewModel, NotificationsState>(
      NotificationsViewModel.new,
    );
final ordersViewModelProvider = NotifierProvider<OrdersViewModel, OrdersState>(
  OrdersViewModel.new,
);

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);

final searchViewModelProvider = NotifierProvider<SearchViewModel, SearchState>(
  SearchViewModel.new,
);

final blogViewModelProvider = NotifierProvider<BlogViewModel, BlogState>(
  BlogViewModel.new,
);

final pagesViewModelProvider = NotifierProvider<PagesViewModel, PagesState>(
  PagesViewModel.new,
);
final wishlistViewModelProvider =
    NotifierProvider<WishlistViewModel, WishlistState>(WishlistViewModel.new);
