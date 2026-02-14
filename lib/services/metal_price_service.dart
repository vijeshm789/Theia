import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/metal_price.dart';
import '../utils/constants.dart';

class MetalPriceService {
  final http.Client _client;

  MetalPriceService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches live metal prices.
  /// Falls back to mock data if the API is unavailable.
  Future<List<MetalPrice>> fetchLivePrices() async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.metalPriceBaseUrl}/latest'
            '?api_key=${AppConstants.metalPriceApiKey}'
            '&base=USD&currencies=XAU,XAG'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;

        // API returns USD per troy ounce; convert to per gram
        final goldOzPrice = 1.0 / (rates['XAU'] as num).toDouble();
        final silverOzPrice = 1.0 / (rates['XAG'] as num).toDouble();

        final goldGramPrice = goldOzPrice / 31.1035;
        final silverGramPrice = silverOzPrice / 31.1035;

        final prices = _buildPriceList(goldGramPrice, silverGramPrice);
        await _cachePrices(prices);
        return prices;
      }
    } catch (_) {
      // Fall through to mock data
    }

    return _getMockPrices();
  }

  /// Fetches historical price data for a given metal and time range.
  Future<MetalPriceHistory> fetchHistory(String metal, String timeRange) async {
    try {
      final days = _timeRangeToDays(timeRange);
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final response = await _client.get(
        Uri.parse('${AppConstants.metalPriceBaseUrl}/timeframe'
            '?api_key=${AppConstants.metalPriceApiKey}'
            '&start_date=${_formatApiDate(startDate)}'
            '&end_date=${_formatApiDate(endDate)}'
            '&base=USD'
            '&currencies=${metal == "Gold" ? "XAU" : "XAG"}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        final symbol = metal == 'Gold' ? 'XAU' : 'XAG';

        final prices = rates.entries.map((entry) {
          final price = 1.0 / (entry.value[symbol] as num).toDouble();
          return PricePoint(
            date: DateTime.parse(entry.key),
            price: price / 31.1035,
          );
        }).toList();

        prices.sort((a, b) => a.date.compareTo(b.date));

        return MetalPriceHistory(
          metal: metal,
          timeRange: timeRange,
          prices: prices,
        );
      }
    } catch (_) {
      // Fall through to mock data
    }

    return _getMockHistory(metal, timeRange);
  }

  List<MetalPrice> _buildPriceList(
      double goldGramPrice, double silverGramPrice) {
    final now = DateTime.now();
    final random = Random();
    final goldChange = (random.nextDouble() - 0.4) * 2;
    final silverChange = (random.nextDouble() - 0.4) * 0.5;

    return [
      MetalPrice(
        metal: AppConstants.gold,
        price: goldGramPrice,
        dailyChange: goldChange,
        percentChange: (goldChange / goldGramPrice) * 100,
        lastUpdated: now,
        unit: 'g',
        karat: AppConstants.gold24k,
      ),
      MetalPrice(
        metal: AppConstants.gold,
        price: goldGramPrice * 0.9167,
        dailyChange: goldChange * 0.9167,
        percentChange: (goldChange / goldGramPrice) * 100,
        lastUpdated: now,
        unit: 'g',
        karat: AppConstants.gold22k,
      ),
      MetalPrice(
        metal: AppConstants.silver,
        price: silverGramPrice,
        dailyChange: silverChange,
        percentChange: (silverChange / silverGramPrice) * 100,
        lastUpdated: now,
        unit: 'g',
      ),
      MetalPrice(
        metal: AppConstants.silver,
        price: silverGramPrice * 1000,
        dailyChange: silverChange * 1000,
        percentChange: (silverChange / silverGramPrice) * 100,
        lastUpdated: now,
        unit: 'kg',
      ),
    ];
  }

  List<MetalPrice> _getMockPrices() {
    final now = DateTime.now();
    return [
      MetalPrice(
        metal: AppConstants.gold,
        price: 76.42,
        dailyChange: 0.85,
        percentChange: 1.12,
        lastUpdated: now,
        unit: 'g',
        karat: AppConstants.gold24k,
      ),
      MetalPrice(
        metal: AppConstants.gold,
        price: 70.05,
        dailyChange: 0.78,
        percentChange: 1.12,
        lastUpdated: now,
        unit: 'g',
        karat: AppConstants.gold22k,
      ),
      MetalPrice(
        metal: AppConstants.silver,
        price: 0.92,
        dailyChange: -0.02,
        percentChange: -2.13,
        lastUpdated: now,
        unit: 'g',
      ),
      MetalPrice(
        metal: AppConstants.silver,
        price: 920.00,
        dailyChange: -20.00,
        percentChange: -2.13,
        lastUpdated: now,
        unit: 'kg',
      ),
    ];
  }

  MetalPriceHistory _getMockHistory(String metal, String timeRange) {
    final days = _timeRangeToDays(timeRange);
    final now = DateTime.now();
    final random = Random(42);
    final basePrice = metal == 'Gold' ? 76.0 : 0.90;
    final volatility = metal == 'Gold' ? 3.0 : 0.08;

    final prices = <PricePoint>[];
    double currentPrice = basePrice;

    final pointCount = days <= 1 ? 24 : days;
    for (int i = 0; i < pointCount; i++) {
      final date = days <= 1
          ? now.subtract(Duration(hours: pointCount - i))
          : now.subtract(Duration(days: days - i));

      currentPrice += (random.nextDouble() - 0.48) * volatility;
      currentPrice = currentPrice.clamp(
          basePrice - volatility * 3, basePrice + volatility * 3);

      prices.add(PricePoint(date: date, price: currentPrice));
    }

    return MetalPriceHistory(
      metal: metal,
      timeRange: timeRange,
      prices: prices,
    );
  }

  int _timeRangeToDays(String timeRange) {
    switch (timeRange) {
      case '1D':
        return 1;
      case '7D':
        return 7;
      case '3D':
        return 3;
      case '5D':
        return 5;
      case '1M':
        return 30;
      case '6M':
        return 180;
      case '1Y':
        return 365;
      default:
        return 30;
    }
  }

  String _formatApiDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _cachePrices(List<MetalPrice> prices) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prices.map((p) => json.encode(p.toJson())).toList();
    await prefs.setStringList('cached_prices', jsonList);
    await prefs.setString(
      AppConstants.lastUpdateTimeKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<List<MetalPrice>?> getCachedPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('cached_prices');
    if (jsonList == null) return null;

    return jsonList
        .map((s) => MetalPrice.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }
}
