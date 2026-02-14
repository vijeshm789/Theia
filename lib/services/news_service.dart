import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';
import '../utils/constants.dart';

class NewsService {
  final http.Client _client;

  NewsService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches latest news articles related to gold, silver, and precious metals.
  Future<List<NewsArticle>> fetchNews({int page = 1}) async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.newsBaseUrl}/everything'
            '?q=gold+silver+precious+metals+commodity'
            '&sortBy=publishedAt'
            '&pageSize=20'
            '&page=$page'
            '&apiKey=${AppConstants.newsApiKey}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final articles = data['articles'] as List;

        return articles
            .map((a) => NewsArticle.fromJson(a as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Fall through to mock data
    }

    return _getMockNews();
  }

  List<NewsArticle> _getMockNews() {
    final now = DateTime.now();
    return [
      NewsArticle(
        id: '1',
        title: 'Gold Prices Surge to New Highs Amid Global Uncertainty',
        description:
            'Gold prices reached new record levels as investors seek safe-haven '
            'assets amid rising geopolitical tensions and economic uncertainty.',
        source: 'Reuters',
        url: 'https://example.com/gold-surge',
        imageUrl: null,
        publishedAt: now.subtract(const Duration(hours: 1)),
      ),
      NewsArticle(
        id: '2',
        title: 'Silver Demand Expected to Rise with Green Energy Push',
        description:
            'Industrial demand for silver is forecasted to increase significantly '
            'as solar panel production ramps up globally.',
        source: 'Bloomberg',
        url: 'https://example.com/silver-demand',
        imageUrl: null,
        publishedAt: now.subtract(const Duration(hours: 3)),
      ),
      NewsArticle(
        id: '3',
        title: 'Central Banks Continue Gold Buying Spree in 2026',
        description:
            'Central banks around the world have increased their gold reserves '
            'for the third consecutive quarter, driving spot prices higher.',
        source: 'Financial Times',
        url: 'https://example.com/central-banks',
        imageUrl: null,
        publishedAt: now.subtract(const Duration(hours: 5)),
      ),
      NewsArticle(
        id: '4',
        title: 'Precious Metals Market Outlook: What to Expect This Quarter',
        description:
            'Analysts weigh in on the precious metals market, highlighting key '
            'factors that could influence gold and silver prices in the coming months.',
        source: 'CNBC',
        url: 'https://example.com/market-outlook',
        imageUrl: null,
        publishedAt: now.subtract(const Duration(hours: 8)),
      ),
      NewsArticle(
        id: '5',
        title: 'Dollar Weakness Boosts Commodity Prices Across the Board',
        description:
            'A weakening US dollar has provided a tailwind for commodity prices, '
            'with gold and silver among the biggest beneficiaries.',
        source: 'MarketWatch',
        url: 'https://example.com/dollar-weakness',
        imageUrl: null,
        publishedAt: now.subtract(const Duration(hours: 12)),
      ),
      NewsArticle(
        id: '6',
        title: 'Inflation Data Sends Gold Higher as Investors Hedge',
        description:
            'Higher-than-expected inflation numbers have pushed gold prices up '
            'as investors look for inflation hedges.',
        source: 'Wall Street Journal',
        url: 'https://example.com/inflation-gold',
        imageUrl: null,
        publishedAt: now.subtract(const Duration(hours: 16)),
      ),
      NewsArticle(
        id: '7',
        title: 'Silver Price Forecast: Technical Analysis Points to Breakout',
        description:
            'Technical analysts are watching silver closely as it approaches a key '
            'resistance level that could trigger a significant breakout.',
        source: 'Kitco',
        url: 'https://example.com/silver-technical',
        imageUrl: null,
        publishedAt: now.subtract(const Duration(hours: 20)),
      ),
      NewsArticle(
        id: '8',
        title: 'Gold Mining Stocks Rally as Metal Prices Climb',
        description:
            'Major gold mining companies saw their stock prices surge as the '
            'underlying metal hit multi-month highs.',
        source: 'Mining Weekly',
        url: 'https://example.com/mining-rally',
        imageUrl: null,
        publishedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
