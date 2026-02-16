import 'dart:math';
import '../models/metal_price.dart';
import '../models/prediction.dart';

class PredictionService {
  /// Generates AI-based price predictions.
  /// In production, this would call a backend ML service.
  /// Currently uses a sophisticated mock that simulates prediction behavior.
  Future<PricePrediction> getPrediction({
    required String metal,
    required String window,
    required double currentPrice,
    List<PricePoint>? historicalData,
  }) async {
    // Simulate network delay for AI processing
    await Future.delayed(const Duration(milliseconds: 800));

    return _generateMockPrediction(
      metal: metal,
      window: window,
      currentPrice: currentPrice,
      historicalData: historicalData,
    );
  }

  PricePrediction _generateMockPrediction({
    required String metal,
    required String window,
    required double currentPrice,
    List<PricePoint>? historicalData,
  }) {
    final random = Random();
    final now = DateTime.now();

    // Calculate trend from historical data if available
    double trendBias = 0.02;
    if (historicalData != null && historicalData.length >= 2) {
      final recentPrice = historicalData.last.price;
      final olderPrice = historicalData[historicalData.length ~/ 2].price;
      trendBias = (recentPrice - olderPrice) / olderPrice;
    }

    // Determine prediction parameters based on window
    final int forecastPoints;
    final Duration pointInterval;
    final double volatilityMultiplier;

    switch (window) {
      case 'Next Day':
        forecastPoints = 24;
        pointInterval = const Duration(hours: 1);
        volatilityMultiplier = 0.002;
        break;
      case 'Next Week':
        forecastPoints = 7;
        pointInterval = const Duration(days: 1);
        volatilityMultiplier = 0.008;
        break;
      case 'Next Month':
        forecastPoints = 30;
        pointInterval = const Duration(days: 1);
        volatilityMultiplier = 0.025;
        break;
      default:
        forecastPoints = 7;
        pointInterval = const Duration(days: 1);
        volatilityMultiplier = 0.008;
    }

    // Generate forecast points with trend
    final points = <PricePoint>[];
    double price = currentPrice;
    final baseVolatility = currentPrice * volatilityMultiplier;

    for (int i = 1; i <= forecastPoints; i++) {
      final date = now.add(pointInterval * i);
      final drift = trendBias * baseVolatility * 0.5;
      final noise = (random.nextDouble() - 0.5) * baseVolatility;
      price += drift + noise;
      price = price.clamp(currentPrice * 0.9, currentPrice * 1.15);
      points.add(PricePoint(date: date, price: price));
    }

    final predictedPrice = points.last.price;
    final change = predictedPrice - currentPrice;
    final percentChange = (change / currentPrice) * 100;

    // Determine trend direction
    TrendDirection trend;
    if (percentChange > 0.5) {
      trend = TrendDirection.uptrend;
    } else if (percentChange < -0.5) {
      trend = TrendDirection.downtrend;
    } else {
      trend = TrendDirection.stable;
    }

    // Confidence decreases with longer prediction windows
    final confidence = switch (window) {
      'Next Day' => 0.75 + random.nextDouble() * 0.15,
      'Next Week' => 0.60 + random.nextDouble() * 0.15,
      'Next Month' => 0.45 + random.nextDouble() * 0.15,
      _ => 0.60,
    };

    // Generate insight summary
    final summary = _generateSummary(metal, trend, percentChange, window);

    return PricePrediction(
      metal: metal,
      window: window,
      predictedPrice: predictedPrice,
      currentPrice: currentPrice,
      trend: trend,
      confidenceLevel: confidence,
      summary: summary,
      forecastPoints: points,
      generatedAt: now,
    );
  }

  String _generateSummary(
    String metal,
    TrendDirection trend,
    double percentChange,
    String window,
  ) {
    final absChange = percentChange.abs().toStringAsFixed(1);

    switch (trend) {
      case TrendDirection.uptrend:
        final reasons = [
          'increased demand and global uncertainty',
          'weakening dollar and inflation concerns',
          'strong central bank buying activity',
          'rising geopolitical tensions',
          'technical breakout above resistance levels',
        ];
        final reason = reasons[Random().nextInt(reasons.length)];
        return '$metal likely to rise ~$absChange% over the $window due to $reason.';

      case TrendDirection.downtrend:
        final reasons = [
          'profit-taking after recent highs',
          'strengthening dollar outlook',
          'reduced safe-haven demand',
          'rising bond yields',
          'technical correction from overbought levels',
        ];
        final reason = reasons[Random().nextInt(reasons.length)];
        return '$metal may decline ~$absChange% over the $window due to $reason.';

      case TrendDirection.stable:
        return '$metal expected to remain relatively stable over the $window, '
            'with prices consolidating near current levels.';
    }
  }
}
