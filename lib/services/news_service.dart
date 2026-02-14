import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/news_article.dart';
import '../utils/constants.dart';

class NewsService {
  final http.Client _client;

  NewsService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches latest news articles related to gold, silver, and precious metals.
  /// Uses Google News RSS (free, no API key) as primary source.
  /// Falls back to NewsAPI.org if a valid key is configured, then to mock data.
  Future<List<NewsArticle>> fetchNews({int page = 1}) async {
    // 1. Try Google News RSS first (free, no API key needed)
    try {
      final articles = await _fetchFromGoogleNewsRss(page: page);
      if (articles.isNotEmpty) return articles;
    } catch (_) {
      // Fall through to next source
    }

    // 2. Try NewsAPI.org if a real key is configured
    if (AppConstants.newsApiKey != 'YOUR_NEWS_API_KEY') {
      try {
        final articles = await _fetchFromNewsApi(page: page);
        if (articles.isNotEmpty) return articles;
      } catch (_) {
        // Fall through to mock data
      }
    }

    // 3. Fallback to mock data
    return _getMockNews();
  }

  /// Fetches articles from Google News RSS feed.
  /// This is completely free and requires no API key.
  Future<List<NewsArticle>> _fetchFromGoogleNewsRss({int page = 1}) async {
    // Google News RSS supports searching by query
    final queries = [
      'gold+price',
      'silver+price',
      'precious+metals+market',
    ];

    final allArticles = <NewsArticle>[];

    for (final query in queries) {
      final url = '${AppConstants.googleNewsRssUrl}'
          '?q=$query'
          '&hl=en-US&gl=US&ceid=US:en';

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Theia/1.0',
          'Accept': 'application/rss+xml, application/xml, text/xml',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final articles = _parseRssFeed(response.body);
        allArticles.addAll(articles);
      }
    }

    // Deduplicate by title
    final seen = <String>{};
    final unique = <NewsArticle>[];
    for (final article in allArticles) {
      if (seen.add(article.title)) {
        unique.add(article);
      }
    }

    // Sort by date (newest first)
    unique.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    // Paginate (20 articles per page)
    const pageSize = 20;
    final start = (page - 1) * pageSize;
    if (start >= unique.length) return [];

    return unique.skip(start).take(pageSize).toList();
  }

  /// Parses an RSS XML feed into a list of NewsArticle objects.
  List<NewsArticle> _parseRssFeed(String rssXml) {
    final articles = <NewsArticle>[];

    try {
      final document = xml.XmlDocument.parse(rssXml);
      final items = document.findAllElements('item');

      for (final item in items) {
        try {
          final title = _getElementText(item, 'title') ?? 'Untitled';
          final link = _getElementText(item, 'link') ?? '';
          final pubDate = _getElementText(item, 'pubDate');
          final description = _getElementText(item, 'description');
          final source = _getElementText(item, 'source');

          // Parse the publication date
          DateTime publishedAt;
          if (pubDate != null) {
            publishedAt = _parseRssDate(pubDate);
          } else {
            publishedAt = DateTime.now();
          }

          // Try to extract image from description HTML or media:content
          String? imageUrl;
          final mediaContent = item.findElements('media:content');
          if (mediaContent.isNotEmpty) {
            imageUrl = mediaContent.first.getAttribute('url');
          }
          // Fallback: try to find an img tag in description
          if (imageUrl == null && description != null) {
            imageUrl = _extractImageFromHtml(description);
          }

          // Clean the HTML from description
          final cleanDescription = _stripHtml(description ?? '');

          articles.add(NewsArticle(
            id: link.isNotEmpty ? link : title.hashCode.toString(),
            title: _stripHtml(title),
            description: cleanDescription.isNotEmpty ? cleanDescription : null,
            source: source ?? 'Google News',
            url: link,
            imageUrl: imageUrl,
            publishedAt: publishedAt,
          ));
        } catch (_) {
          // Skip malformed items
          continue;
        }
      }
    } catch (_) {
      // Return whatever we parsed so far
    }

    return articles;
  }

  /// Gets text content of a child XML element.
  String? _getElementText(xml.XmlElement parent, String elementName) {
    final elements = parent.findElements(elementName);
    if (elements.isEmpty) return null;
    final text = elements.first.innerText.trim();
    return text.isNotEmpty ? text : null;
  }

  /// Parses RSS date format (RFC 822) like "Fri, 14 Feb 2026 10:30:00 GMT".
  DateTime _parseRssDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      // Try RFC 822 format manually
      try {
        return _parseRfc822Date(dateStr);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  /// Manually parses RFC 822 date strings.
  DateTime _parseRfc822Date(String dateStr) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
      'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
      'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };

    // "Fri, 14 Feb 2026 10:30:00 GMT"
    final cleaned = dateStr.replaceAll(RegExp(r'^[A-Za-z]+,\s*'), '');
    final parts = cleaned.split(RegExp(r'\s+'));

    if (parts.length >= 4) {
      final day = int.parse(parts[0]);
      final month = months[parts[1]] ?? 1;
      final year = int.parse(parts[2]);
      final timeParts = parts[3].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
      final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

      return DateTime.utc(year, month, day, hour, minute, second);
    }

    return DateTime.now();
  }

  /// Extracts the first image URL from HTML content.
  String? _extractImageFromHtml(String html) {
    final regex = RegExp(r'<img[^>]+src="([^"]+)"');
    final match = regex.firstMatch(html);
    return match?.group(1);
  }

  /// Strips HTML tags from a string.
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  /// Fetches articles from NewsAPI.org (requires valid API key).
  Future<List<NewsArticle>> _fetchFromNewsApi({int page = 1}) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.newsBaseUrl}/everything'
          '?q=gold+silver+precious+metals+commodity'
          '&sortBy=publishedAt'
          '&pageSize=20'
          '&page=$page'
          '&apiKey=${AppConstants.newsApiKey}'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final articles = data['articles'] as List;

      return articles
          .map((a) => NewsArticle.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return [];
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
