import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/features/pages/presentation/widgets/page_templates.dart';

/// One built-in brand or policy page (see [builtInPageTemplate]).
class PageDetailScreen extends StatelessWidget {
  const PageDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final template = builtInPageTemplate(slug);
    return Scaffold(
      appBar: AppBar(title: Text(template?.title ?? 'Trang')),
      body: template == null
          ? const Center(child: Text('Không tìm thấy trang'))
          : BuiltInPageBody(template: template),
    );
  }
}
