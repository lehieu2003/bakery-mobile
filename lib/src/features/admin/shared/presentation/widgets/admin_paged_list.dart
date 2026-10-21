// Shared paged list for admin screens: search field, filter chip row and an
// infinite-scroll list with pull-to-refresh, loading/empty/error states.
//
// Pagination trigger: ScrollController listener on the internal stateful body
// (chosen over NotificationListener<ScrollNotification> for determinism — no
// reliance on notification bubbling through nested scrollables). It fires
// onLoadMore when the viewport is within 600px of the bottom, only while
// hasMore && !isLoadingMore && !isLoading && error == null. A local guard
// re-arms on prop changes (items length / isLoadingMore) so one scroll burst
// requests one page.
import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/shared/widgets/loading_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/empty_state_widget.dart';

/// Một lựa chọn lọc cho hàng chip: [value] null là chip 'Tất cả'.
class AdminFilterChip {
  const AdminFilterChip({required this.label, required this.value});

  final String label;

  /// null = không lọc (hiển thị tất cả).
  final String? value;
}

/// Danh sách phân trang dùng chung cho các màn hình admin: ô tìm kiếm, hàng
/// chip lọc, pull-to-refresh, cuộn gần đáy tự tải thêm, footer spinner và
/// các trạng thái loading / empty / error.
class AdminPagedList<T> extends StatelessWidget {
  const AdminPagedList({
    super.key,
    required this.items,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.onRefresh,
    required this.itemBuilder,
    required this.searchHint,
    this.searchText,
    this.onSearchChanged,
    this.filters = const [],
    this.selectedFilter,
    this.onFilterSelected,
    this.emptyText = 'Chưa có dữ liệu',
  });

  final List<T> items;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext, T) itemBuilder;

  final String searchHint;

  /// Text hiện tại của ô tìm kiếm (điều khiển từ VM); null coi như rỗng.
  final String? searchText;
  final ValueChanged<String>? onSearchChanged;

  final List<AdminFilterChip> filters;

  /// Giá trị chip đang chọn; null tương ứng chip có [AdminFilterChip.value]
  /// == null ('Tất cả').
  final String? selectedFilter;
  final ValueChanged<String?>? onFilterSelected;

  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onSearchChanged != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _AdminSearchField(
              hint: searchHint,
              text: searchText ?? '',
              onChanged: onSearchChanged!,
            ),
          ),
        if (filters.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final filter in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: selectedFilter == filter.value,
                      onSelected: onFilterSelected == null
                          ? null
                          : (_) => onFilterSelected!(filter.value),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const LoadingWidget();
    }
    if (error != null && items.isEmpty) {
      return ErrorRetryWidget(message: error!, onRetry: onRetry);
    }
    if (items.isEmpty) {
      return EmptyStateWidget(message: emptyText);
    }
    return _AdminPagedListBody<T>(
      items: items,
      itemBuilder: itemBuilder,
      isLoading: isLoading,
      error: error,
      onRetry: onRetry,
      isLoadingMore: isLoadingMore,
      hasMore: hasMore,
      onLoadMore: onLoadMore,
      onRefresh: onRefresh,
    );
  }
}

/// Ô tìm kiếm điều khiển từ ngoài: text luôn khớp [text] khi parent rebuild
/// (dùng khi VM xoá tìm kiếm), kèm nút X xoá nhanh khi đang có text.
class _AdminSearchField extends StatefulWidget {
  const _AdminSearchField({
    required this.hint,
    required this.text,
    required this.onChanged,
  });

  final String hint;
  final String text;
  final ValueChanged<String> onChanged;

  @override
  State<_AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends State<_AdminSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void didUpdateWidget(covariant _AdminSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _controller.text) {
      _controller
        ..text = widget.text
        ..selection = TextSelection.collapsed(offset: widget.text.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        isDense: true,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: hasText
            ? IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
      ),
    );
  }
}

/// Phần danh sách: ScrollController listener kích hoạt [onLoadMore] khi gần
/// đáy (xem chú thích đầu file), RefreshIndicator + footer spinner/error.
class _AdminPagedListBody<T> extends StatefulWidget {
  const _AdminPagedListBody({
    required this.items,
    required this.itemBuilder,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.onRefresh,
  });

  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;

  @override
  State<_AdminPagedListBody<T>> createState() => _AdminPagedListBodyState<T>();
}

class _AdminPagedListBodyState<T> extends State<_AdminPagedListBody<T>> {
  static const double _loadMoreThreshold = 600;

  final ScrollController _controller = ScrollController();
  bool _loadMoreRequested = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _AdminPagedListBody<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Page mới về hoặc trạng thái tải thêm đổi → cho phép yêu cầu tiếp.
    if (oldWidget.items.length != widget.items.length ||
        oldWidget.isLoadingMore != widget.isLoadingMore) {
      _loadMoreRequested = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadMoreRequested) return;
    if (!widget.hasMore || widget.isLoadingMore || widget.isLoading) return;
    if (widget.error != null) return;
    final position = _controller.position;
    if (!position.hasContentDimensions) return;
    if (position.maxScrollExtent - position.pixels <= _loadMoreThreshold) {
      _loadMoreRequested = true;
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Footer spinner khi đang tải thêm; khi tải thêm lỗi (error != null) mà
    // còn trang kế tiếp, hiển thị lỗi + 'Thử lại' ngay dưới items.
    final showFooter =
        widget.isLoadingMore || (widget.error != null && widget.hasMore);
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: widget.items.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= widget.items.length) return _buildFooter(context);
          return widget.itemBuilder(context, widget.items[index]);
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (widget.isLoadingMore) {
      return const LoadingWidget(
        size: 24,
        padding: EdgeInsets.symmetric(vertical: 16),
      );
    }
    if (widget.error != null) {
      return ErrorRetryWidget(
        message: widget.error!,
        onRetry: widget.onRetry,
        compact: true,
      );
    }
    return const SizedBox.shrink();
  }
}
