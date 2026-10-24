import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/content/banners/domain/models/admin_banner.dart';
import 'package:bakery_mobile/src/features/admin/content/banners/presentation/controllers/banners_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/content/banners/presentation/widgets/banner_edit_sheet.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';

/// Banner admin: ordered list with up/down reorder, add/edit sheet and
/// delete confirm. Banners are few — a plain list, not paged.
class BannersScreen extends ConsumerStatefulWidget {
  const BannersScreen({super.key});

  @override
  ConsumerState<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends ConsumerState<BannersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(bannersAdminViewModelProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bannersAdminViewModelProvider);
    final vm = ref.read(bannersAdminViewModelProvider.notifier);

    return Scaffold(
      body: state.isLoading && state.banners.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.banners.isEmpty
          ? ErrorRetryWidget(message: state.error!, onRetry: vm.load)
          : state.banners.isEmpty
          ? Center(
              child: Text(
                'Chưa có banner nào',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : RefreshIndicator(
              onRefresh: vm.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: state.banners.length,
                separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                itemBuilder: (context, index) {
                  final banner = state.banners[index];
                  return _BannerCard(
                    banner: banner,
                    isFirst: index == 0,
                    isLast: index == state.banners.length - 1,
                    onUp: () => vm.move(index, up: true),
                    onDown: () => vm.move(index, up: false),
                    onEdit: () => showBannerEditSheet(context, banner: banner),
                    onDelete: () => _confirmDelete(banner),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showBannerEditSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm banner'),
      ),
    );
  }

  Future<void> _confirmDelete(AdminBanner banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá banner?'),
        content: Text('"${banner.title}" sẽ bị gỡ khỏi trang chủ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(bannersAdminViewModelProvider.notifier).remove(banner.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xoá banner')));
    }
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.isFirst,
    required this.isLast,
    required this.onUp,
    required this.onDown,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminBanner banner;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 48,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.canvasCream,
                ),
                child: banner.imageUrl == null
                    ? const Icon(Icons.image_outlined, size: 24)
                    : AppNetworkImageWidget(url: banner.imageUrl!),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (banner.description != null)
                      Text(
                        banner.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    Text(
                      banner.isActive ? 'Đang hiện' : 'Ẩn',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: banner.isActive
                            ? Colors.green.shade700
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 20),
                    onPressed: isFirst ? null : onUp,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 20),
                    onPressed: isLast ? null : onDown,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
