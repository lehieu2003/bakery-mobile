import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

class SettingsAdminState {
  const SettingsAdminState({
    this.values = const {},
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  final Map<String, String> values;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  SettingsAdminState copyWith({
    Map<String, String>? values,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSaving,
  }) {
    return SettingsAdminState(
      values: values ?? this.values,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Drives the "Cài đặt" screen: flat key/value store settings form.
class SettingsAdminViewModel extends Notifier<SettingsAdminState> {
  @override
  SettingsAdminState build() => const SettingsAdminState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(settingsAdminRepositoryProvider);
    try {
      final values = await repo.getSettings();
      state = state.copyWith(values: values, isLoading: false);
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  /// PUTs the full settings map; server stores flat keys.
  Future<bool> save(Map<String, String> fields) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(settingsAdminRepositoryProvider);
    try {
      await repo.putSettings(fields);
      state = state.copyWith(values: fields, isSaving: false);
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

final settingsAdminViewModelProvider =
    NotifierProvider<SettingsAdminViewModel, SettingsAdminState>(
      SettingsAdminViewModel.new,
    );
