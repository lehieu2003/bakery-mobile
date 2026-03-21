import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bakery_mobile/src/features/blog/domain/models/blog.dart';
import 'package:bakery_mobile/src/features/blog/data/repositories/blog_repository.dart';

class BlogDetailScreen extends StatefulWidget {
  const BlogDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  BlogPost? _post;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<BlogRepository>();
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
      appBar: AppBar(title: const Text('Blog detail')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
          ? const Center(child: Text('Post not found'))
          : ListView(
              padding: const EdgeInsets.all(16),
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
                if (_post!.coverUrl != null && _post!.coverUrl!.isNotEmpty)
                  Image.network(
                    _post!.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
    );
  }
}


