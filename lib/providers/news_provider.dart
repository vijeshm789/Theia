import 'package:flutter/foundation.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';

class NewsProvider extends ChangeNotifier {
  final NewsService _service;

  List<NewsArticle> _articles = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  NewsProvider({NewsService? service}) : _service = service ?? NewsService();

  // Getters
  List<NewsArticle> get articles => _articles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  /// Fetches the latest news articles.
  Future<void> fetchNews() async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();

    try {
      _articles = await _service.fetchNews(page: 1);
      _hasMore = _articles.length >= 20;
    } catch (e) {
      _error = 'Failed to load news. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Loads the next page of articles.
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _currentPage++;
    try {
      final newArticles = await _service.fetchNews(page: _currentPage);
      _articles.addAll(newArticles);
      _hasMore = newArticles.length >= 20;
    } catch (_) {
      _currentPage--;
    }

    notifyListeners();
  }

  /// Refreshes the news feed.
  Future<void> refresh() async {
    await fetchNews();
  }
}
