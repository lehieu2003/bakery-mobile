import 'package:flutter/widgets.dart';

/// Widget keys of the blog screen (used by tests and finders).
abstract final class BlogKeys {
  static const search = Key('blog.search');
  static const loading = Key('blog.loading');
  static const list = Key('blog.list');
  static const empty = Key('blog.empty');
  static const error = Key('blog.error');
  static const errorBanner = Key('blog.errorBanner');
  static const loadingMore = Key('blog.loadingMore');
  static const loadMore = Key('blog.loadMore');
  static const allCategories = Key('blog.category.all');

  static Key category(String slug) => Key('blog.category.$slug');
  static Key tag(String slug) => Key('blog.tag.$slug');
  static Key post(String id) => Key('blog.post.$id');
}
