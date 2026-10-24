import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/coupons/domain/models/coupon_models.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

class CouponsAdminState {
  const CouponsAdminState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  final List<AdminCoupon> items;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  CouponsAdminState copyWith({
    List<AdminCoupon>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSaving,
  }) {
    return CouponsAdminState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Drives the Coupon admin screen: list + create + delete + active toggle.
class CouponsAdminViewModel extends Notifier<CouponsAdminState> {
  @override
  CouponsAdminState build() => const CouponsAdminState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(couponAdminRepositoryProvider);
    try {
      final items = await repo.getCoupons();
      state = state.copyWith(items: items, isLoading: false);
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  /// Creates a coupon. Server rules mirrored client-side: code 3-40
  /// [A-Z0-9_-], PERCENTAGE value 1..100, endAt after startAt.
  Future<bool> create({
    required String code,
    required String type,
    required double value,
    required DateTime startAt,
    required DateTime endAt,
    double? minOrder,
    double? maxDiscount,
    int? usageLimit,
    int? perUserLimit,
  }) async {
    final error = _validate(
      code: code,
      type: type,
      value: value,
      startAt: startAt,
      endAt: endAt,
    );
    if (error != null) {
      state = state.copyWith(error: error);
      return false;
    }
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(couponAdminRepositoryProvider);
    try {
      await repo.createCoupon({
        'code': code.trim().toUpperCase(),
        'type': type,
        'value': value,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        if (minOrder != null) 'minOrder': minOrder,
        if (maxDiscount != null) 'maxDiscount': maxDiscount,
        if (usageLimit != null) 'usageLimit': usageLimit,
        if (perUserLimit != null) 'perUserLimit': perUserLimit,
      });
      await load();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isSaving: false);
        return false;
      }
      state = state.copyWith(isSaving: false, error: _message(error));
      return false;
    }
  }

  Future<bool> remove(String id) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(couponAdminRepositoryProvider);
    try {
      await repo.deleteCoupon(id);
      state = state.copyWith(
        items: state.items.where((c) => c.id != id).toList(),
        isSaving: false,
      );
      return true;
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isSaving: false);
        return false;
      }
      state = state.copyWith(isSaving: false, error: _message(error));
      return false;
    }
  }

  Future<bool> setActive(String id, {required bool isActive}) async {
    final repo = ref.read(couponAdminRepositoryProvider);
    try {
      await repo.setCouponActive(id, isActive: isActive);
      state = state.copyWith(
        items: [
          for (final coupon in state.items)
            if (coupon.id == id)
              AdminCoupon(
                id: coupon.id,
                code: coupon.code,
                type: coupon.type,
                value: coupon.value,
                minOrder: coupon.minOrder,
                maxDiscount: coupon.maxDiscount,
                usageLimit: coupon.usageLimit,
                perUserLimit: coupon.perUserLimit,
                startAt: coupon.startAt,
                endAt: coupon.endAt,
                isActive: isActive,
              )
            else
              coupon,
        ],
      );
      return true;
    } catch (error) {
      if (await _logoutOn401(error)) {
        return false;
      }
      state = state.copyWith(error: _message(error));
      return false;
    }
  }

  String? _validate({
    required String code,
    required String type,
    required double value,
    required DateTime startAt,
    required DateTime endAt,
  }) {
    final normalized = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9_-]{3,40}$').hasMatch(normalized)) {
      return 'Mã coupon 3-40 ký tự (A-Z, 0-9, _, -)';
    }
    if (value <= 0) return 'Giá trị phải lớn hơn 0';
    if (type == 'PERCENTAGE' && value > 100) return 'Phần trăm tối đa 100';
    if (!endAt.isAfter(startAt)) return 'Ngày kết thúc phải sau ngày bắt đầu';
    return null;
  }

  Future<bool> _logoutOn401(Object error) async {
    if (error is ApiException && error.statusCode == 401) {
      await ref.read(authViewModelProvider.notifier).logout();
      return true;
    }
    return false;
  }

  String _message(Object error) => userErrorMessage(error);
}

final couponsAdminViewModelProvider =
    NotifierProvider<CouponsAdminViewModel, CouponsAdminState>(
      CouponsAdminViewModel.new,
    );
