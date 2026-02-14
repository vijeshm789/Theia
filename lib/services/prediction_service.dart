import 'dart:convert';
import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/metal_price.dart';
import '../models/prediction.dart';
import '../utils/constants.dart';

class PredictionService {
  GenerativeModel? _model;

  GenerativeModel _getModel() {
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash-lite',
      apiKey: AppConstants.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
        responseMimeType: 'application/json',
      ),
    );
    return _model!;
  }

  /// Generates AI-based price predictions using Gemini Flash.
  /// Falls back to local algorithm if Gemini is unavailable.
  Future<PricePrediction> getPrediction({
    required String metal,
    required String window,
    required double currentPrice,
    List<PricePoint>? historicalData,
  }) async {
    try {
      return await _getGeminiPrediction(
        metal: metal,
        window: window,
        currentPrice: currentPrice,
        historicalData: historicalData,
      );
    } catch (_) {
      // Fallback to local algorithm if Gemini fails
      return _generateLocalPrediction(
        metal: metal,
        window: window,
        currentPrice: currentPrice,
        historicalData: historicalData,
      );
    }
  }

  /// Call Gemini Flash for AI-powered prediction.
  Future<PricePrediction> _getGeminiPrediction({
    required String metal,
    required String window,
    required double currentPrice,
    List<PricePoint>? historicalData,
  }) async {
    final model = _getModel();

    // Build historical context for the prompt
    final historyContext = _buildHistoryContext(historicalData);

    final prompt = '''
You are a precious metals market analyst AI. Analyze the following data and provide a price prediction.

Metal: $metal
Current Price: ₹${currentPrice.toStringAsFixed(2)} per gram
Prediction Window: $window
$historyContext

Based on recent market trends, global economic factors, currency movements, central bank policies, and supply-demand dynamics, provide your prediction as JSON with exactly these fields:

{
  "predicted_price": <number - predicted price in INR per gram>,
  "trend": "<uptrend|downtrend|stable>",
  "confidence": <number between 0.0 and 1.0>,
  "summary": "<2-3 sentence analysis explaining your prediction with specific market factors>"
}

Guidelines:
- For "Next Day": price change should be within ±2% of current price, confidence 0.65-0.85
- For "Next Week": price change should be within ±5% of current price, confidence 0.50-0.75
- For "Next Month": price change should be within ±10% of current price, confidence 0.35-0.60
- The summary should mention specific factors like dollar strength, inflation, geopolitics, central bank activity, or technical levels
- Be realistic — precious metals rarely have extreme single-day moves
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;

    if (text == null || text.isEmpty) {
      throw Exception('Empty Gemini response');
    }

    final json = jsonDecode(text) as Map<String, dynamic>;

    final predictedPrice = (json['predicted_price'] as num).toDouble();
    final trendStr = json['trend'] as String;
    final confidence = (json['confidence'] as num).toDouble();
    final summary = json['summary'] as String;

    final trend = switch (trendStr) {
      'uptrend' => TrendDirection.uptrend,
      'downtrend' => TrendDirection.downtrend,
      _ => TrendDirection.stable,
    };

    // Generate forecast points interpolating between current and predicted
    final forecastPoints = _generateForecastPoints(
      currentPrice: currentPrice,
      predictedPrice: predictedPrice,
      window: window,
      trend: trend,
    );

    return PricePrediction(
      metal: metal,
      window: window,
      predictedPrice: predictedPrice,
      currentPrice: currentPrice,
      trend: trend,
      confidenceLevel: confidence.clamp(0.0, 1.0),
      summary: summary,
      forecastPoints: forecastPoints,
      generatedAt: DateTime.now(),
    );
  }

  String _buildHistoryContext(List<PricePoint>? historicalData) {
    if (historicalData == null || historicalData.isEmpty) {
      return 'Historical data: Not available';
    }

    // Send last 10 data points to keep prompt concise
    final recentPoints = historicalData.length > 10
        ? historicalData.sublist(historicalData.length - 10)
        : historicalData;

    final buffer = StringBuffer('Recent price history (INR/gram):\n');
    for (final point in recentPoints) {
      buffer.writeln(
          '  ${point.date.toIso8601String().split('T').first}: ₹${point.price.toStringAsFixed(2)}');
    }

    // Add basic stats
    final prices = historicalData.map((p) => p.price).toList();
    final high = prices.reduce(max);
    final low = prices.reduce(min);
    final avg = prices.reduce((a, b) => a + b) / prices.length;
    final firstPrice = prices.first;
    final lastPrice = prices.last;
    final periodChange = ((lastPrice - firstPrice) / firstPrice * 100);

    buffer.writeln('Period high: ₹${high.toStringAsFixed(2)}');
    buffer.writeln('Period low: ₹${low.toStringAsFixed(2)}');
    buffer.writeln('Period average: ₹${avg.toStringAsFixed(2)}');
    buffer.writeln(
        'Period change: ${periodChange >= 0 ? '+' : ''}${periodChange.toStringAsFixed(2)}%');

    return buffer.toString();
  }

  /// Generate smooth forecast points between current and predicted price.
  List<PricePoint> _generateForecastPoints({
    required double currentPrice,
    required double predictedPrice,
    required String window,
    required TrendDirection trend,
  }) {
    final random = Random();
    final now = DateTime.now();

    final int numPoints;
    final Duration interval;

    switch (window) {
      case 'Next Day':
        numPoints = 24;
        interval = const Duration(hours: 1);
        break;
      case 'Next Week':
        numPoints = 7;
        interval = const Duration(days: 1);
        break;
      case 'Next Month':
        numPoints = 30;
        interval = const Duration(days: 1);
        break;
      default:
        numPoints = 7;
        interval = const Duration(days: 1);
    }

    final points = <PricePoint>[];
    final totalChange = predictedPrice - currentPrice;

    for (int i = 1; i <= numPoints; i++) {
      final progress = i / numPoints;
      // Ease-in-out interpolation for natural look
      final eased = progress < 0.5
          ? 2 * progress * progress
          : 1 - (-2 * progress + 2) * (-2 * progress + 2) / 2;

      final basePrice = currentPrice + totalChange * eased;
      // Add small noise for realistic chart
      final noise = (random.nextDouble() - 0.5) * currentPrice * 0.002;
      final price = i == numPoints ? predictedPrice : basePrice + noise;

      points.add(PricePoint(
        date: now.add(interval * i),
        price: price,
      ));
    }

    return points;
  }

  // ── Local fallback (used when Gemini is unavailable) ──

  PricePrediction _generateLocalPrediction({
    required String metal,
    required String window,
    required double currentPrice,
    List<PricePoint>? historicalData,
  }) {
    final random = Random();
    final now = DateTime.now();

    double trendBias = 0.02;
    if (historicalData != null && historicalData.length >= 2) {
      final recentPrice = historicalData.last.price;
      final olderPrice = historicalData[historicalData.length ~/ 2].price;
      trendBias = (recentPrice - olderPrice) / olderPrice;
    }

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
    final percentChange =
        ((predictedPrice - currentPrice) / currentPrice) * 100;

    TrendDirection trend;
    if (percentChange > 0.5) {
      trend = TrendDirection.uptrend;
    } else if (percentChange < -0.5) {
      trend = TrendDirection.downtrend;
    } else {
      trend = TrendDirection.stable;
    }

    final confidence = switch (window) {
      'Next Day' => 0.75 + random.nextDouble() * 0.15,
      'Next Week' => 0.60 + random.nextDouble() * 0.15,
      'Next Month' => 0.45 + random.nextDouble() * 0.15,
      _ => 0.60,
    };

    final summary = _generateLocalSummary(metal, trend, percentChange, window);

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

  String _generateLocalSummary(
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
        return '$metal likely to rise ~$absChange% over the $window due to $reason. (Offline prediction)';

      case TrendDirection.downtrend:
        final reasons = [
          'profit-taking after recent highs',
          'strengthening dollar outlook',
          'reduced safe-haven demand',
          'rising bond yields',
          'technical correction from overbought levels',
        ];
        final reason = reasons[Random().nextInt(reasons.length)];
        return '$metal may decline ~$absChange% over the $window due to $reason. (Offline prediction)';

      case TrendDirection.stable:
        return '$metal expected to remain relatively stable over the $window, '
            'with prices consolidating near current levels. (Offline prediction)';
    }
  }
}
