import 'package:flutter/material.dart';
import '../models/prediction.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class PredictionCard extends StatelessWidget {
  final PricePrediction prediction;

  const PredictionCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final trendColor = _getTrendColor(prediction.trend);
    final trendIcon = _getTrendIcon(prediction.trend);
    final isGold = prediction.metal == AppConstants.gold;
    final accentColor = isGold ? AppTheme.primaryGold : AppTheme.secondarySilver;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'AI Forecast — ${prediction.window}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, color: trendColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      prediction.trendLabel,
                      style: TextStyle(
                        color: trendColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Price prediction row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Price',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(prediction.currentPrice),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: AppTheme.textMuted.withOpacity(0.5),
                size: 20,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Predicted Price',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(prediction.predictedPrice),
                      style: TextStyle(
                        color: trendColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Change display
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${Formatters.formatPriceChange(prediction.priceChange)} '
              '(${Formatters.formatPercentChange(prediction.percentChange)})',
              style: TextStyle(
                color: trendColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Confidence bar
          _ConfidenceBar(level: prediction.confidenceLevel),
          const SizedBox(height: 16),

          // AI Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.orangeAccent.withOpacity(0.8),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    prediction.summary,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.uptrend:
        return AppTheme.profitGreen;
      case TrendDirection.downtrend:
        return AppTheme.lossRed;
      case TrendDirection.stable:
        return AppTheme.stableYellow;
    }
  }

  IconData _getTrendIcon(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.uptrend:
        return Icons.trending_up;
      case TrendDirection.downtrend:
        return Icons.trending_down;
      case TrendDirection.stable:
        return Icons.trending_flat;
    }
  }
}

class _ConfidenceBar extends StatelessWidget {
  final double level;

  const _ConfidenceBar({required this.level});

  @override
  Widget build(BuildContext context) {
    final percentage = (level * 100).round();
    Color barColor;
    if (level >= 0.7) {
      barColor = AppTheme.profitGreen;
    } else if (level >= 0.5) {
      barColor = AppTheme.stableYellow;
    } else {
      barColor = AppTheme.lossRed;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Confidence Level',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                color: barColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: level,
            backgroundColor: AppTheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
