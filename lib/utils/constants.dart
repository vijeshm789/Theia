class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Theia';
  static const String appTagline = 'See the future of precious metal markets';

  // API Endpoints (placeholder - replace with actual API keys/endpoints)
  static const String metalPriceBaseUrl = 'https://api.metalpriceapi.com/v1';
  static const String newsBaseUrl = 'https://newsapi.org/v2';

  // API Keys (move to secure storage in production)
  static const String metalPriceApiKey = '4019bd580849f63c0354fe6cca292e7e';
  static const String newsApiKey = '610f5606fdbb417696f09c3f617ee921';

  // Gemini AI (free tier — 15 RPM / 1M tokens per day)
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';

  // Shopify Storefront API
  static const String shopifyStoreDomain = 'YOUR_STORE.myshopify.com';
  static const String shopifyStorefrontAccessToken = 'YOUR_STOREFRONT_ACCESS_TOKEN';

  // Cache Keys - Auth
  static const String cachedAccessTokenKey = 'shopify_access_token';
  static const String cachedCustomerIdKey = 'shopify_customer_id';

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
