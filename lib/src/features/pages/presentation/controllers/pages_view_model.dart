import 'package:flutter/foundation.dart';

import 'package:bakery_mobile/src/features/pages/domain/models/app_page.dart';
import 'package:bakery_mobile/src/features/pages/data/repositories/page_repository.dart';

class PagesViewModel extends ChangeNotifier {
  PagesViewModel(this._pageRepository);

  final PageRepository _pageRepository;

  bool _isLoading = false;
  String? _error;
  List<AppPageSummary> _pages = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AppPageSummary> get pages => _pages;

  Future<void> loadPages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pages = await _pageRepository.getPages();
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AppPageDetail?> loadPageDetail(String slug) async {
    try {
      return await _pageRepository.getPageBySlug(slug);
    } catch (_) {
      return null;
    }
  }
}


