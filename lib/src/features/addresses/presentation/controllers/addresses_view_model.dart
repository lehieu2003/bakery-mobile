import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/addresses/domain/models/address.dart';

class AddressesState {
  const AddressesState({
    this.isLoading = false,
    this.error,
    this.items = const [],
    this.pendingId,
  });

  final bool isLoading;
  final String? error;
  final List<Address> items;

  /// Id of the address with an in-flight mutation (delete / setDefault).
  final String? pendingId;

  Address? defaultOrFirst() {
    if (items.isEmpty) return null;
    return items.firstWhere(
      (item) => item.isDefault,
      orElse: () => items.first,
    );
  }

  AddressesState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Address>? items,
    String? pendingId,
    bool clearPendingId = false,
  }) {
    return AddressesState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
      pendingId: clearPendingId ? null : (pendingId ?? this.pendingId),
    );
  }
}

class AddressesViewModel extends Notifier<AddressesState> {
  @override
  AddressesState build() => const AddressesState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await ref.read(addressRepositoryProvider).getAddresses();
      state = state.copyWith(isLoading: false, items: items);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Creates an address and reloads so server-side default rules
  /// (first address is default; new default unsets others) are reflected.
  /// Returns the created address, or null when creation failed.
  Future<Address?> add({
    required String fullName,
    required String phone,
    required String street,
    required String ward,
    required String district,
    required String province,
    bool isDefault = false,
  }) async {
    state = state.copyWith(clearError: true);
    try {
      final created = await ref
          .read(addressRepositoryProvider)
          .createAddress(
            fullName: fullName,
            phone: phone,
            street: street,
            ward: ward,
            district: district,
            province: province,
            isDefault: isDefault,
          );
      await _reload();
      return created;
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  /// Partially updates an address and reloads. Pass `isDefault: true` to make
  /// it the single default (the server unsets the other defaults).
  Future<bool> update(
    String id, {
    String? fullName,
    String? phone,
    String? street,
    String? ward,
    String? district,
    String? province,
    bool? isDefault,
  }) async {
    state = state.copyWith(clearError: true);
    try {
      await ref
          .read(addressRepositoryProvider)
          .updateAddress(
            id,
            fullName: fullName,
            phone: phone,
            street: street,
            ward: ward,
            district: district,
            province: province,
            isDefault: isDefault,
          );
      await _reload();
      return true;
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = state.copyWith(pendingId: id, clearError: true);
    try {
      await ref.read(addressRepositoryProvider).deleteAddress(id);
      await _reload();
      return true;
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    } finally {
      state = state.copyWith(clearPendingId: true);
    }
  }

  Future<bool> setDefault(String id) {
    return update(id, isDefault: true);
  }

  /// Refreshes the list after a mutation without flashing the loading state.
  Future<void> _reload() async {
    try {
      final items = await ref.read(addressRepositoryProvider).getAddresses();
      state = state.copyWith(items: items);
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
