class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Theia';
  static const String appTagline = 'See the future of precious metal markets';

  // API Endpoints
  static const String metalPriceBaseUrl = 'https://api.metalpriceapi.com/v1';
  static const String newsBaseUrl = 'https://newsapi.org/v2';

  // Google News RSS (free, no API key required)
  static const String googleNewsRssUrl = 'https://news.google.com/rss/search';

  // API Keys (move to secure storage in production)
  // Metal price API key - register at metalpriceapi.com for free
  static const String metalPriceApiKey = 'YOUR_METAL_PRICE_API_KEY';
  // NewsAPI key (optional) - Google News RSS is used as primary free source
  // Register at newsapi.org if you want NewsAPI as a secondary source
  static const String newsApiKey = 'YOUR_NEWS_API_KEY';

  // Refresh Intervals
  static const Duration autoRefreshInterval = Duration(minutes: 5);
  static const Duration newsRefreshInterval = Duration(minutes: 15);

  // Cache Keys
  static const String cachedGoldPriceKey = 'cached_gold_price';
  static const String cachedSilverPriceKey = 'cached_silver_price';
  static const String cachedNewsKey = 'cached_news';
  static const String lastUpdateTimeKey = 'last_update_time';

  // Chart Time Filters
  static const List<String> chartTimeFilters = [
    '1D',
    '7D',
    '1M',
    '6M',
    '1Y',
  ];

  // Prediction Windows
  static const List<String> predictionWindows = [
    'Next Day',
    'Next Week',
    'Next Month',
  ];

  // Metal Types
  static const String gold = 'Gold';
  static const String silver = 'Silver';

  // Gold Karat Types
  static const String gold24k = '24K';
  static const String gold22k = '22K';

  // Disclaimer
  static const String predictionDisclaimer =
      'Predictions are informational only and do not constitute financial advice. '
      'Past performance is not indicative of future results.';
}
