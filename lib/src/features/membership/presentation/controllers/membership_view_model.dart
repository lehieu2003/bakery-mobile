import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/membership/domain/models/membership_benefits.dart';

class MembershipState {
  const MembershipState({
    this.benefits,
    this.isLoading = false,
    this.errorMessage,
  });

  final MembershipBenefits? benefits;
  final bool isLoading;
  final String? errorMessage;

  MembershipState copyWith({
    MembershipBenefits? benefits,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MembershipState(
      benefits: benefits ?? this.benefits,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MembershipViewModel extends Notifier<MembershipState> {
  @override
  MembershipState build() => const MembershipState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final benefits = await ref
          .read(membershipRepositoryProvider)
          .getBenefits();
      state = state.copyWith(benefits: benefits, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
