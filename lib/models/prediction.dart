import 'metal_price.dart';

enum TrendDirection { uptrend, downtrend, stable }

class PricePrediction {
  final String metal;
  final String window;
  final double predictedPrice;
  final double currentPrice;
  final TrendDirection trend;
  final double confidenceLevel;
  final String summary;
  final List<PricePoint> forecastPoints;
  final DateTime generatedAt;

  const PricePrediction({
    required this.metal,
    required this.window,
    required this.predictedPrice,
    required this.currentPrice,
    required this.trend,
    required this.confidenceLevel,
    required this.summary,
    required this.forecastPoints,
    required this.generatedAt,
  });

  double get priceChange => predictedPrice - currentPrice;
  double get percentChange =>
      currentPrice > 0 ? ((predictedPrice - currentPrice) / currentPrice) * 100 : 0;

  String get trendLabel {
    switch (trend) {
      case TrendDirection.uptrend:
        return 'Uptrend';
      case TrendDirection.downtrend:
        return 'Downtrend';
      case TrendDirection.stable:
        return 'Stable';
    }
  }

  factory PricePrediction.fromJson(Map<String, dynamic> json) {
    return PricePrediction(
      metal: json['metal'] as String,
      window: json['window'] as String,
      predictedPrice: (json['predicted_price'] as num).toDouble(),
      currentPrice: (json['current_price'] as num).toDouble(),
      trend: TrendDirection.values.firstWhere(
        (t) => t.name == json['trend'],
        orElse: () => TrendDirection.stable,
      ),
      confidenceLevel: (json['confidence_level'] as num).toDouble(),
      summary: json['summary'] as String,
      forecastPoints: (json['forecast_points'] as List?)
              ?.map((p) => PricePoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }
}
