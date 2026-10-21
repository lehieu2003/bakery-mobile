import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/pages/domain/models/app_page.dart';
import 'package:bakery_mobile/src/features/pages/presentation/states/static_page_fallbacks.dart';
import 'package:bakery_mobile/src/features/pages/presentation/widgets/page_templates.dart';
import 'package:bakery_mobile/src/shared/widgets/loading_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class PageDetailScreen extends ConsumerStatefulWidget {
  const PageDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<PageDetailScreen> createState() => _PageDetailScreenState();
}

class _PageDetailScreenState extends ConsumerState<PageDetailScreen> {
  AppPageDetail? _page;
  bool _isLoading = true;
  PageTemplateData? _template;

  @override
  void initState() {
    super.initState();
    _template = builtInPageTemplate(widget.slug);
    if (_template != null) {
      _isLoading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final repo = ref.read(pageRepositoryProvider);
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
      appBar: AppBar(title: Text(_template?.title ?? _page?.title ?? 'Page')),
      body: _isLoading
          ? const LoadingWidget()
          : _template != null
          ? BuiltInPageBody(template: _template!)
          : _page == null
          ? const Center(child: Text('Page not found'))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  _page!.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Gap(AppSpacing.md),
                Html(data: _page!.content),
              ],
            ),
    );
  }
}
