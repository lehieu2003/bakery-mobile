import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bakery_mobile/src/features/pages/domain/models/app_page.dart';
import 'package:bakery_mobile/src/features/pages/data/repositories/page_repository.dart';
import 'package:bakery_mobile/src/features/pages/presentation/states/static_page_fallbacks.dart';

class PageDetailScreen extends StatefulWidget {
  const PageDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<PageDetailScreen> createState() => _PageDetailScreenState();
}

class _PageDetailScreenState extends State<PageDetailScreen> {
  AppPageDetail? _page;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<PageRepository>();
    try {
      final page = await repo.getPageBySlug(widget.slug);
      if (!mounted) return;
      setState(() => _page = page);
    } catch (_) {
      final fallback = staticPageFallbacks[widget.slug];
      if (fallback != null && mounted) {
        setState(
          () => _page = AppPageDetail(
            id: 'static-${fallback.slug}',
            title: fallback.title,
            slug: fallback.slug,
            content: fallback.content,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_page?.title ?? 'Page')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _page == null
          ? const Center(child: Text('Page not found'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _page!.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Html(data: _page!.content),
              ],
            ),
    );
  }
}


