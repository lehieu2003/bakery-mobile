import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/pages/domain/models/app_page.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

class PagesState {
  const PagesState({this.isLoading = false, this.error, this.pages = const []});

  final bool isLoading;
  final String? error;
  final List<AppPageSummary> pages;

  PagesState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<AppPageSummary>? pages,
  }) {
    return PagesState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      pages: pages ?? this.pages,
    );
  }
}

class PagesViewModel extends Notifier<PagesState> {
  @override
  PagesState build() => const PagesState();

  Future<void> loadPages() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final pages = await ref.read(pageRepositoryProvider).getPages();
      state = state.copyWith(isLoading: false, pages: pages);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: userErrorMessage(error));
    }
  }
}
