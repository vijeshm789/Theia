class MetalPrice {
  final String metal;
  final double price;
  final double dailyChange;
  final double percentChange;
  final DateTime lastUpdated;
  final String unit;
  final String? karat;

  const MetalPrice({
    required this.metal,
    required this.price,
    required this.dailyChange,
    required this.percentChange,
    required this.lastUpdated,
    this.unit = 'g',
    this.karat,
  });

  bool get isProfit => dailyChange >= 0;

  factory MetalPrice.fromJson(Map<String, dynamic> json) {
    return MetalPrice(
      metal: json['metal'] as String,
      price: (json['price'] as num).toDouble(),
      dailyChange: (json['daily_change'] as num).toDouble(),
      percentChange: (json['percent_change'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      unit: json['unit'] as String? ?? 'g',
      karat: json['karat'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metal': metal,
      'price': price,
      'daily_change': dailyChange,
      'percent_change': percentChange,
      'last_updated': lastUpdated.toIso8601String(),
      'unit': unit,
      'karat': karat,
    };
  }
}

class PricePoint {
  final DateTime date;
  final double price;

  const PricePoint({
    required this.date,
    required this.price,
  });

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      date: DateTime.parse(json['date'] as String),
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'price': price,
    };
  }
}

class MetalPriceHistory {
  final String metal;
  final String timeRange;
  final List<PricePoint> prices;

  const MetalPriceHistory({
    required this.metal,
    required this.timeRange,
    required this.prices,
  });

  double get highestPrice =>
      prices.map((p) => p.price).reduce((a, b) => a > b ? a : b);

  double get lowestPrice =>
      prices.map((p) => p.price).reduce((a, b) => a < b ? a : b);

  double get latestPrice => prices.isNotEmpty ? prices.last.price : 0;

  factory MetalPriceHistory.fromJson(Map<String, dynamic> json) {
    return MetalPriceHistory(
      metal: json['metal'] as String,
      timeRange: json['time_range'] as String,
      prices: (json['prices'] as List)
          .map((p) => PricePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
