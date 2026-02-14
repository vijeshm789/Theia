import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/news_article.dart';

class NewsService {
  final http.Client _client;

  /// Google News RSS search URL (no API key required).
  static const _googleNewsRssUrl = 'https://news.google.com/rss/search';

  NewsService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches latest news articles about gold, silver, and precious metals
  /// from Google News RSS. Falls back to mock data on failure.
  Future<List<NewsArticle>> fetchNews({int page = 1}) async {
    try {
      final uri = Uri.parse(_googleNewsRssUrl).replace(queryParameters: {
        'q': 'gold silver precious metals commodity',
        'hl': 'en-US',
        'gl': 'US',
        'ceid': 'US:en',
      });

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        final articles = items.map((item) {
          final title = _elementText(item, 'title') ?? '';
          final link = _elementText(item, 'link') ?? '';
          final description = _stripHtml(_elementText(item, 'description'));
          final source = _elementText(item, 'source');
          final pubDateStr = _elementText(item, 'pubDate');

          DateTime? pubDate;
          if (pubDateStr != null) {
            pubDate = _parseRssDate(pubDateStr);
          }

          return NewsArticle.fromRss(
            title: _cleanGoogleTitle(title, source),
            link: link,
            description: description,
            source: source,
            pubDate: pubDate,
          );
        }).toList();

        if (articles.isNotEmpty) {
          // Simulate pagination: 20 items per page
          const pageSize = 20;
          final start = (page - 1) * pageSize;
          if (start >= articles.length) return [];
          final end =
              (start + pageSize) > articles.length ? articles.length : start + pageSize;
          return articles.sublist(start, end);
        }
      }
    } catch (_) {
      // Fall through to mock data
    }

    return _getMockNews();
  }

  /// Extract text content from an XML element by tag name.
  String? _elementText(xml.XmlElement parent, String tag) {
    final elements = parent.findElements(tag);
    if (elements.isEmpty) return null;
    return elements.first.innerText.trim();
  }

  /// Google News titles often end with " - SourceName". Remove the suffix
  /// since we display the source separately.
  String _cleanGoogleTitle(String title, String? source) {
    if (source != null && title.endsWith(' - $source')) {
      return title.substring(0, title.length - ' - $source'.length).trim();
    }
    return title;
  }

  /// Strip HTML tags from a string.
  String? _stripHtml(String? html) {
    if (html == null || html.isEmpty) return null;
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  /// Parse RFC 822 / RFC 2822 date strings used in RSS feeds.
  DateTime? _parseRssDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      // RFC 822 format: "Sat, 14 Feb 2026 10:00:00 GMT"
      try {
        const months = {
          'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
          'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
          'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
        };
        final parts = dateStr.replaceAll(',', '').split(RegExp(r'\s+'));
        // Expected: [Day, DD, Mon, YYYY, HH:MM:SS, TZ]
        if (parts.length >= 5) {
          final day = int.parse(parts[1]);
          final month = months[parts[2]] ?? 1;
          final year = int.parse(parts[3]);
          final timeParts = parts[4].split(':');
          final hour = int.parse(timeParts[0]);
          final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
          final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
          return DateTime.utc(year, month, day, hour, minute, second);
        }
      } catch (_) {
        // Give up on parsing
      }
    }
    return null;
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
