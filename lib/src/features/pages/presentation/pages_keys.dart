import 'package:flutter/widgets.dart';

/// Widget keys of the pages screen (used by tests and finders).
abstract final class PagesKeys {
  static const loading = Key('pages.loading');
  static const list = Key('pages.list');
  static const error = Key('pages.error');

  static Key item(String slug) => Key('pages.item.$slug');
}
