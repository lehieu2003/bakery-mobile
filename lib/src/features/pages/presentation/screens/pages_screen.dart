import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bakery_mobile/src/features/pages/domain/models/app_page.dart';
import 'package:bakery_mobile/src/features/pages/data/repositories/page_repository.dart';
import 'package:bakery_mobile/src/features/pages/presentation/screens/page_detail_screen.dart';
import 'package:bakery_mobile/src/features/pages/presentation/controllers/pages_view_model.dart';
import 'package:bakery_mobile/src/features/pages/presentation/states/static_page_fallbacks.dart';

class PagesScreen extends StatelessWidget {
  const PagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          PagesViewModel(context.read<PageRepository>())..loadPages(),
      child: const _PagesView(),
    );
  }
}

class _PagesView extends StatelessWidget {
  const _PagesView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagesViewModel>();

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
        onRefresh: vm.loadPages,
        child: ListView(
          children: [
            if (vm.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  vm.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ...merged.map(
              (page) => ListTile(
                title: Text(page.title),
                subtitle: Text('/${page.slug}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PageDetailScreen(slug: page.slug),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


