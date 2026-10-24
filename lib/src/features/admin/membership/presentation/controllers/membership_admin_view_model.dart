import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/membership/domain/models/membership_models.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

class MembershipAdminState {
  const MembershipAdminState({
    this.config,
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  final MembershipConfig? config;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  MembershipAdminState copyWith({
    MembershipConfig? config,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSaving,
  }) {
    return MembershipAdminState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Drives the "Thành viên" screen: 3 tier cards (minPoints editable) +
/// points-per-order card. Every save PUTs the full config
/// (`{levels:[{key,minPoints}],pointsPerOrder}`) — the server contract.
class MembershipAdminViewModel extends Notifier<MembershipAdminState> {
  @override
  MembershipAdminState build() => const MembershipAdminState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(membershipAdminRepositoryProvider);
    try {
      final config = await repo.getMembership();
      state = state.copyWith(config: config, isLoading: false);
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  /// Persists a new minPoints for one tier (or pointsPerOrder when
  /// [tierKey] is null) and reloads. Non-positive values are rejected.
  /// Persists a new minPoints for one tier (or pointsPerOrder when
  /// [tierKey] is null) and reloads. The server contract requires all
  /// three levels as `{level, minPoints, discountPercent}` plus
  /// pointsPerOrder. Non-negative values only.
  Future<bool> updateConfig({String? tierKey, required int value}) async {
    if (value < 0) {
      state = state.copyWith(error: 'Điểm phải lớn hơn hoặc bằng 0');
      return false;
    }
    final config = state.config;
    if (config == null || state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(membershipAdminRepositoryProvider);
    try {
      await repo.putMembership({
        'levels': [
          for (final level in config.levels)
            {
              'level': level.level,
              'minPoints': level.level == tierKey ? value : level.minPoints,
              'discountPercent': level.discountPercent,
            },
        ],
        'pointsPerOrder': tierKey == null ? value : config.pointsPerOrder,
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

  Future<bool> _logoutOn401(Object error) async {
    if (error is ApiException && error.statusCode == 401) {
      await ref.read(authViewModelProvider.notifier).logout();
      return true;
    }
    return false;
  }

  String _message(Object error) => userErrorMessage(error);
}

final membershipAdminViewModelProvider =
    NotifierProvider<MembershipAdminViewModel, MembershipAdminState>(
      MembershipAdminViewModel.new,
    );
