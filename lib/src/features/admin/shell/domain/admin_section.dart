import 'package:flutter/material.dart';

/// Sidebar module grouping — group order mirrors the web admin sidebar:
/// Tổng quan · Đơn hàng, Khách hàng, Coupon · Sản phẩm, Danh mục,
/// Bộ lọc sản phẩm, Thành viên, Banner · Blog, Thông báo ·
/// Nhật ký hệ thống, Cài đặt.
enum AdminSectionGroup { overview, sales, store, content, system }

extension AdminSectionGroupX on AdminSectionGroup {
  /// Drawer header label (pinned Vietnamese group names).
  String get vietnameseTitle => switch (this) {
    AdminSectionGroup.overview => 'Tổng quan',
    AdminSectionGroup.sales => 'Bán hàng',
    AdminSectionGroup.store => 'Cửa hàng',
    AdminSectionGroup.content => 'Nội dung',
    AdminSectionGroup.system => 'Hệ thống',
  };

  /// Sections of this group in sidebar display order.
  List<AdminSection> get sections => switch (this) {
    AdminSectionGroup.overview => const [AdminSection.dashboard],
    AdminSectionGroup.sales => const [
      AdminSection.orders,
      AdminSection.customers,
      AdminSection.coupons,
    ],
    AdminSectionGroup.store => const [
      AdminSection.products,
      AdminSection.categories,
      AdminSection.productAttributes,
      AdminSection.membership,
      AdminSection.banners,
    ],
    AdminSectionGroup.content => const [
      AdminSection.blog,
      AdminSection.notifications,
    ],
    AdminSectionGroup.system => const [
      AdminSection.audit,
      AdminSection.settings,
    ],
  };
}

/// The 13 admin modules. Enum declaration order is pinned by the plan; the
/// sidebar display order comes from [AdminSectionGroupX.sections].
enum AdminSection {
  dashboard,
  orders,
  customers,
  coupons,
  products,
  categories,
  productAttributes,
  membership,
  banners,
  notifications,
  blog,
  audit,
  settings,
}

extension AdminSectionX on AdminSection {
  /// Pinned Vietnamese labels (web sidebar parity).
  String get vietnameseTitle => switch (this) {
    AdminSection.dashboard => 'Tổng quan',
    AdminSection.orders => 'Đơn hàng',
    AdminSection.customers => 'Khách hàng',
    AdminSection.coupons => 'Coupon',
    AdminSection.products => 'Sản phẩm',
    AdminSection.categories => 'Danh mục',
    AdminSection.productAttributes => 'Bộ lọc sản phẩm',
    AdminSection.membership => 'Thành viên',
    AdminSection.banners => 'Banner',
    AdminSection.notifications => 'Thông báo',
    AdminSection.blog => 'Blog',
    AdminSection.audit => 'Nhật ký hệ thống',
    AdminSection.settings => 'Cài đặt',
  };

  AdminSectionGroup get group => switch (this) {
    AdminSection.dashboard => AdminSectionGroup.overview,
    AdminSection.orders => AdminSectionGroup.sales,
    AdminSection.customers => AdminSectionGroup.sales,
    AdminSection.coupons => AdminSectionGroup.sales,
    AdminSection.products => AdminSectionGroup.store,
    AdminSection.categories => AdminSectionGroup.store,
    AdminSection.productAttributes => AdminSectionGroup.store,
    AdminSection.membership => AdminSectionGroup.store,
    AdminSection.banners => AdminSectionGroup.store,
    AdminSection.blog => AdminSectionGroup.content,
    AdminSection.notifications => AdminSectionGroup.content,
    AdminSection.audit => AdminSectionGroup.system,
    AdminSection.settings => AdminSectionGroup.system,
  };

  IconData get icon => switch (this) {
    AdminSection.dashboard => Icons.dashboard_outlined,
    AdminSection.orders => Icons.receipt_long_outlined,
    AdminSection.customers => Icons.people_outline,
    AdminSection.coupons => Icons.local_offer_outlined,
    AdminSection.products => Icons.inventory_2_outlined,
    AdminSection.categories => Icons.category_outlined,
    AdminSection.productAttributes => Icons.filter_alt_outlined,
    AdminSection.membership => Icons.card_membership_outlined,
    AdminSection.banners => Icons.image_outlined,
    AdminSection.notifications => Icons.notifications_outlined,
    AdminSection.blog => Icons.article_outlined,
    AdminSection.audit => Icons.history_outlined,
    AdminSection.settings => Icons.settings_outlined,
  };
}
