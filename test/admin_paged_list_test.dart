import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/shared/presentation/widgets/admin_paged_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Host với MaterialApp + theme thật, widget chiếm toàn màn hình test
/// (800x600) để ListView có viewport đủ lớn cho kịch bản cuộn.
Widget _host(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  ),
);

AdminPagedList<String> _list({
  required List<String> items,
  bool isLoading = false,
  String? error,
  VoidCallback? onRetry,
  bool isLoadingMore = false,
  bool hasMore = false,
  VoidCallback? onLoadMore,
  String? searchText,
  ValueChanged<String>? onSearchChanged,
  String? selectedFilter,
  ValueChanged<String?>? onFilterSelected,
}) {
  return AdminPagedList<String>(
    items: items,
    isLoading: isLoading,
    error: error,
    onRetry: onRetry ?? () {},
    isLoadingMore: isLoadingMore,
    hasMore: hasMore,
    onLoadMore: onLoadMore ?? () {},
    onRefresh: () async {},
    itemBuilder: (context, item) => SizedBox(height: 56, child: Text(item)),
    searchHint: 'Tìm đơn hàng',
    searchText: searchText,
    onSearchChanged: onSearchChanged,
    filters: const [
      AdminFilterChip(label: 'Tất cả', value: null),
      AdminFilterChip(label: 'Đã xác nhận', value: 'CONFIRMED'),
      AdminFilterChip(label: 'Đang giao', value: 'SHIPPING'),
    ],
    selectedFilter: selectedFilter,
    onFilterSelected: onFilterSelected,
  );
}

/// Danh sách dọc chính nằm dưới RefreshIndicator (hàng chip cũng là ListView
/// ngang, nên phải thu hẹp finder).
Finder _mainList() => find.descendant(
  of: find.byType(RefreshIndicator),
  matching: find.byType(ListView),
);

void main() {
  testWidgets('T1: renders every item through itemBuilder', (tester) async {
    await tester.pumpWidget(_host(_list(items: ['Đơn #1', 'Đơn #2'])));
    await tester.pumpAndSettle();

    expect(find.text('Đơn #1'), findsOneWidget);
    expect(find.text('Đơn #2'), findsOneWidget);
  });

  testWidgets('T2: search field forwards text, X button clears', (
    tester,
  ) async {
    String? typed;
    await tester.pumpWidget(
      _host(
        _list(
          items: ['Đơn #1'],
          searchText: typed,
          onSearchChanged: (value) => typed = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.search), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'bánh mì');
    await tester.pump();
    expect(typed, 'bánh mì');

    // Có text → nút X xuất hiện; tap X → onSearchChanged('').
    await tester.pumpWidget(
      _host(
        _list(
          items: ['Đơn #1'],
          searchText: 'bánh mì',
          onSearchChanged: (value) => typed = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(typed, '');

    // Parent rebuild với searchText rỗng → ô tìm kiếm hiển thị rỗng.
    await tester.pumpWidget(
      _host(
        _list(
          items: ['Đơn #1'],
          searchText: '',
          onSearchChanged: (value) => typed = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('T3: tapping a filter chip forwards its value', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _host(
        _list(
          items: ['Đơn #1'],
          selectedFilter: null,
          onFilterSelected: (value) => selected = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 'Tất cả' (value null) đang được chọn khi selectedFilter null.
    expect(
      tester.widget<ChoiceChip>(find.byType(ChoiceChip).at(0)).selected,
      isTrue,
    );

    await tester.tap(find.text('Đã xác nhận'));
    await tester.pump();
    expect(selected, 'CONFIRMED');

    // Rebuild với selectedFilter 'CONFIRMED' → chip tương ứng selected.
    await tester.pumpWidget(
      _host(
        _list(
          items: ['Đơn #1'],
          selectedFilter: 'CONFIRMED',
          onFilterSelected: (value) => selected = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<ChoiceChip>(find.byType(ChoiceChip).at(1)).selected,
      isTrue,
    );
    expect(
      tester.widget<ChoiceChip>(find.byType(ChoiceChip).at(0)).selected,
      isFalse,
    );
  });

  testWidgets('T4: initial loading shows spinner, then empty text', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_list(items: const [], isLoading: true)));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(_host(_list(items: const [], isLoading: false)));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có dữ liệu'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('T5: error state shows message and Thử lại triggers onRetry', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(
        _list(
          items: const [],
          error: 'Không tải được đơn hàng',
          onRetry: () => retries++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tải được đơn hàng'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('T6: scrolling near bottom loads more only when hasMore', (
    tester,
  ) async {
    var loadMoreCalls = 0;
    await tester.pumpWidget(
      _host(
        _list(
          items: List.generate(30, (i) => 'Đơn #${i + 1}'),
          hasMore: true,
          onLoadMore: () => loadMoreCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Cuộn tới đáy danh sách (30 x 56px > viewport 600px).
    for (var i = 0; i < 6; i++) {
      await tester.drag(_mainList(), const Offset(0, -400));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(loadMoreCalls, greaterThanOrEqualTo(1));
    expect(find.text('Đơn #30'), findsOneWidget);

    // hasMore = false → cuộn tới đáy không gọi onLoadMore.
    var noMoreCalls = 0;
    await tester.pumpWidget(
      _host(
        _list(
          items: List.generate(30, (i) => 'Đơn #${i + 1}'),
          hasMore: false,
          onLoadMore: () => noMoreCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 6; i++) {
      await tester.drag(_mainList(), const Offset(0, -400));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(noMoreCalls, 0);
  });
}
