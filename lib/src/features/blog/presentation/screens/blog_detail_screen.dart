import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/blog/domain/models/blog.dart';

class BlogDetailScreen extends ConsumerStatefulWidget {
  const BlogDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends ConsumerState<BlogDetailScreen> {
  BlogPost? _post;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(blogRepositoryProvider);
    try {
      final post = await repo.getPostBySlug(widget.slug);
      if (!mounted) return;
      setState(() => _post = post);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _post == null
                  ? const Center(child: Text('Post not found'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 52, 16, 16),
                      children: [
                        Text(
                          _post!.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_post!.publishedAt?.toLocal() ?? ''} | ${_post!.viewCount} views',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        if (_post!.coverUrl != null &&
                            _post!.coverUrl!.isNotEmpty)
                          Image.network(
                            _post!.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        const SizedBox(height: 12),
                        if ((_post!.excerpt ?? '').isNotEmpty)
                          Text(_post!.excerpt ?? ''),
                        if ((_post!.content ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Html(data: _post!.content ?? ''),
                        ],
                      ],
                    ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
