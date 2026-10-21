import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/features/pages/domain/models/app_page.dart';
import 'package:bakery_mobile/src/features/pages/presentation/screens/page_detail_screen.dart';
import 'package:bakery_mobile/src/features/pages/presentation/states/static_page_fallbacks.dart';
import 'package:bakery_mobile/src/shared/widgets/loading_widget.dart';

class PagesScreen extends ConsumerStatefulWidget {
  const PagesScreen({super.key});

  @override
  ConsumerState<PagesScreen> createState() => _PagesScreenState();
}

class _PagesScreenState extends ConsumerState<PagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pagesViewModelProvider.notifier).loadPages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(pagesViewModelProvider);
    final scheme = Theme.of(context).colorScheme;

    final dynamicPages = vm.pages;
    final staticPages = staticPageOrder
        .map((slug) => staticPageFallbacks[slug])
        .whereType<StaticPageFallback>()
        .toList();

    final merged = <AppPageSummary>[
      ...staticPages.map(
        (page) => AppPageSummary(
          id: 'static-${page.slug}',
          title: page.title,
          slug: page.slug,
        ),
      ),
      ...dynamicPages.where(
        (page) => !staticPageFallbacks.containsKey(page.slug),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Policy & Pages')),
      body: RefreshIndicator(
        onRefresh: ref.read(pagesViewModelProvider.notifier).loadPages,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.14),
                      scheme.primaryContainer.withValues(alpha: 0.42),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                child: Text(
                  'Thông tin thương hiệu, chính sách và hướng dẫn sử dụng dịch vụ Phương Loan Bakery.',
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                ),
              ),
            ),
            if (vm.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: LoadingWidget(),
              ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  vm.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ...merged.map((page) {
              final fallback = staticPageFallbacks[page.slug];
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PageDetailScreen(slug: page.slug),
                      ),
                    );
                  },
                  child: Ink(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: scheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: Icon(
                            _pageIcon(page.slug),
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                page.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                fallback?.summary ?? '/${page.slug}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _pageIcon(String slug) {
    switch (slug) {
      case 've-chung-toi':
        return Icons.bakery_dining_rounded;
      case 'thanh-vien':
        return Icons.workspace_premium_rounded;
      case 'store':
      case 'cua-hang':
        return Icons.storefront_rounded;
      case 'chinh-sach-bao-mat':
        return Icons.shield_rounded;
      case 'chinh-sach-giao-hang':
        return Icons.local_shipping_rounded;
      case 'chinh-sach-doi-tra':
        return Icons.assignment_return_rounded;
      case 'dieu-khoan-su-dung':
        return Icons.description_rounded;
      default:
        return Icons.article_rounded;
    }
  }
}
